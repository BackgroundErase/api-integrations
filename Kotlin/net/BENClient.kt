package com.example.ben_integration.net

import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody
import okio.BufferedSink
import okio.source
import java.io.IOException
import java.util.UUID
import java.util.concurrent.TimeUnit

object BENClient {

    private val http = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(120, TimeUnit.SECONDS)
        .writeTimeout(120, TimeUnit.SECONDS)
        .build()

    /**
     * Uploads an image at [inputUri] to api.backgrounderase.net/v2 using x-api-key,
     * and saves the returned PNG to Downloads. Returns the saved file's Uri.
     */
    suspend fun removeBackgroundAndSaveToDownloads(
        context: Context,
        inputUri: Uri,
        apiKey: String
    ): Uri = withContext(Dispatchers.IO) {
        // Figure out a filename & mime for the upload part
        val cr = context.contentResolver
        val mime = cr.getType(inputUri) ?: "application/octet-stream"
        val uploadName = queryDisplayName(context, inputUri) ?: "upload-${UUID.randomUUID()}.bin"

        // Stream the content into an OkHttp RequestBody (chunked; no need for contentLength)
        val streamRequestBody = object : RequestBody() {
            override fun contentType() = mime.toMediaTypeOrNull()
            override fun writeTo(sink: BufferedSink) {
                cr.openInputStream(inputUri)?.use { input ->
                    sink.writeAll(input.source())
                } ?: throw IOException("Unable to open input stream for $inputUri")
            }
        }

        // Build multipart/form-data body
        val multipart = MultipartBody.Builder()
            .setType(MultipartBody.FORM)
            .addFormDataPart("image_file", uploadName, streamRequestBody)
            .build()

        // Create request
        val req = Request.Builder()
            .url("https://api.backgrounderase.net/v2")
            .header("x-api-key", apiKey)
            .post(multipart)
            .build()

        // Execute
        val resp = http.newCall(req).execute()
        if (!resp.isSuccessful) {
            val msg = resp.body?.string().orEmpty()
            resp.close()
            throw IOException("HTTP ${resp.code}: ${resp.message}. Body: $msg")
        }

        // Determine output mime/extension from response
        val outMime = resp.header("Content-Type") ?: "image/png"
        val ext = when {
            outMime.contains("png", ignoreCase = true) -> "png"
            outMime.contains("jpeg", ignoreCase = true) || outMime.contains("jpg", ignoreCase = true) -> "jpg"
            else -> "png"
        }
        val outName = "ben-cutout-${UUID.randomUUID()}.$ext"

        // Save to Downloads via MediaStore (scoped storage; no legacy permission required)
        val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        } else {
            MediaStore.Files.getContentUri("external")
        }

        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, outName)
            put(MediaStore.MediaColumns.MIME_TYPE, outMime)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.MediaColumns.RELATIVE_PATH, "Download")
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
        }

        val outUri = cr.insert(collection, values)
            ?: throw IOException("Failed to create output in MediaStore")

        try {
            cr.openOutputStream(outUri)?.use { out ->
                resp.body?.byteStream()?.use { inStream ->
                    inStream.copyTo(out)
                }
            } ?: throw IOException("Failed to open output stream")

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                values.clear()
                values.put(MediaStore.MediaColumns.IS_PENDING, 0)
                cr.update(outUri, values, null, null)
            }

            outUri
        } finally {
            resp.close()
        }
    }

    // Helpers
    private fun queryDisplayName(context: Context, uri: Uri): String? {
        val projection = arrayOf(MediaStore.MediaColumns.DISPLAY_NAME)
        context.contentResolver.query(uri, projection, null, null, null)?.use { c ->
            val i = c.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME)
            if (c.moveToFirst()) return c.getString(i)
        }
        return null
    }
}
