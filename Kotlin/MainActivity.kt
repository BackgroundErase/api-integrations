package com.example.ben_integration

import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.Folder
import androidx.compose.material.icons.outlined.Photo
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.lifecycle.lifecycleScope
import coil.compose.AsyncImage
import com.example.ben_integration.net.BENClient
import com.example.ben_integration.ui.theme.BenintegrationTheme
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : ComponentActivity() {

    // TODO: move to a safer place for release builds.
    private val apiKey =
        "YOUR_API_KEY_HERE"

    // UI state
    private var originalUri by mutableStateOf<Uri?>(null)
    private var resultUri by mutableStateOf<Uri?>(null)
    private var isProcessing by mutableStateOf(false)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        // Pick from Files (system file picker)
        val filesPicker = registerForActivityResult(
            ActivityResultContracts.GetContent()
        ) { uri ->
            originalUri = uri
            resultUri = null
        }

        // Pick from Photos (photo picker)
        val photosPicker = registerForActivityResult(
            ActivityResultContracts.PickVisualMedia()
        ) { uri ->
            originalUri = uri
            resultUri = null
        }

        setContent {
            BenintegrationTheme {
                Scaffold(modifier = Modifier.fillMaxSize()) { inner ->
                    val context = LocalContext.current
                    val scroll = rememberScrollState()

                    Column(
                        modifier = Modifier
                            .padding(inner)
                            .fillMaxSize()
                            .verticalScroll(scroll)
                            .padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        // Header
                        Text(
                            "BEN Background Removal Demo",
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.SemiBold
                        )

                        // Selected file name (chip)
                        originalUri?.let { uri ->
                            val name = remember(uri) { queryDisplayName(uri) ?: "" }
                            if (name.isNotEmpty()) {
                                AssistChip(onClick = {}, label = { Text(name) })
                            }
                        }

                        // Files / Photos row
                        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                            OutlinedButton(
                                onClick = { filesPicker.launch("image/*") },
                                shape = RoundedCornerShape(14.dp),
                                modifier = Modifier.weight(1f)
                            ) {
                                Icon(Icons.Outlined.Folder, contentDescription = null)
                                Spacer(Modifier.width(8.dp))
                                Text("Files")
                            }
                            OutlinedButton(
                                onClick = {
                                    photosPicker.launch(
                                        PickVisualMediaRequest(
                                            ActivityResultContracts.PickVisualMedia.ImageOnly
                                        )
                                    )
                                },
                                shape = RoundedCornerShape(14.dp),
                                modifier = Modifier.weight(1f)
                            ) {
                                Icon(Icons.Outlined.Photo, contentDescription = null)
                                Spacer(Modifier.width(8.dp))
                                Text("Photos")
                            }
                        }

                        // Big blue action button
                        Button(
                            onClick = { originalUri?.let { runBen(apiKey, it) } },
                            enabled = originalUri != null && !isProcessing,
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(52.dp),
                            shape = RoundedCornerShape(16.dp)
                        ) {
                            Text(if (isProcessing) "Processing…" else "Remove Background")
                        }

                        // ORIGINAL (top)
                        originalUri?.let { uri ->
                            Text("Original", style = MaterialTheme.typography.titleMedium)
                            Card(
                                shape = RoundedCornerShape(16.dp),
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                AsyncImage(
                                    model = uri,
                                    contentDescription = "Original image",
                                    contentScale = ContentScale.Fit,
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .heightIn(min = 240.dp)
                                )
                            }
                        }

                        // RESULT (scroll down to see)
                        Text(
                            "Result (PNG w/ transparency)",
                            style = MaterialTheme.typography.titleMedium
                        )

                        if (resultUri != null) {
                            CheckerboardCard(height = 320.dp) {
                                AsyncImage(
                                    model = resultUri,
                                    contentDescription = "Background-removed image",
                                    contentScale = ContentScale.Fit,
                                    modifier = Modifier.fillMaxSize()
                                )
                            }

                            // Save to Photos
                            Button(
                                onClick = {
                                    resultUri?.let { uri ->
                                        lifecycleScope.launch {
                                            try {
                                                val saved = saveImageToPhotos(uri)
                                                Toast.makeText(
                                                    this@MainActivity,
                                                    "Saved to Photos:\n$saved",
                                                    Toast.LENGTH_LONG
                                                ).show()
                                            } catch (e: Exception) {
                                                Toast.makeText(
                                                    this@MainActivity,
                                                    "Save failed: ${e.message}",
                                                    Toast.LENGTH_LONG
                                                ).show()
                                            }
                                        }
                                    }
                                },
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(50.dp),
                                shape = RoundedCornerShape(14.dp)
                            ) {
                                Text("Save to Photos")
                            }

                            // Share / Export
                            OutlinedButton(
                                onClick = { resultUri?.let { shareImage(it) } },
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(50.dp),
                                shape = RoundedCornerShape(14.dp)
                            ) {
                                Text("Share / Export")
                            }
                        } else {
                            if (isProcessing) {
                                LinearProgressIndicator(modifier = Modifier.fillMaxWidth())
                            } else {
                                Text(
                                    "Pick an image, then tap “Remove Background”.",
                                    style = MaterialTheme.typography.bodyMedium
                                )
                            }
                        }

                        // Status row
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Icon(
                                Icons.Outlined.CheckCircle,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.primary
                            )
                            Text("Photos access granted")
                        }
                    }
                }
            }
        }
    }

    /** Kicks off the network call and updates UI state. */
    private fun runBen(apiKey: String, inputUri: Uri) {
        lifecycleScope.launch {
            isProcessing = true
            try {
                val saved = BENClient.removeBackgroundAndSaveToDownloads(
                    context = this@MainActivity,
                    inputUri = inputUri,
                    apiKey = apiKey
                )
                resultUri = saved
                Toast.makeText(
                    this@MainActivity,
                    "Saved to Downloads:\n$saved",
                    Toast.LENGTH_LONG
                ).show()
            } catch (e: Exception) {
                Toast.makeText(this@MainActivity, "Error: ${e.message}", Toast.LENGTH_LONG).show()
            } finally {
                isProcessing = false
            }
        }
    }

    /** Copy [src] into Photos (MediaStore Images) and return the new Uri. */
    private suspend fun saveImageToPhotos(src: Uri): Uri = withContext(Dispatchers.IO) {
        val outCollection =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q)
                MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            else
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI

        val mime = contentResolver.getType(src) ?: "image/png"
        val ext = when {
            "png" in mime.lowercase() -> "png"
            "jpg" in mime.lowercase() || "jpeg" in mime.lowercase() -> "jpg"
            else -> "png"
        }
        val name = "ben-cutout-${System.currentTimeMillis()}.$ext"

        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, name)
            put(MediaStore.MediaColumns.MIME_TYPE, mime)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.MediaColumns.RELATIVE_PATH, "Pictures/BEN")
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
        }

        val out = contentResolver.insert(outCollection, values)
            ?: throw IllegalStateException("Failed to create MediaStore item")

        try {
            contentResolver.openOutputStream(out)?.use { o ->
                contentResolver.openInputStream(src)?.use { i ->
                    i.copyTo(o)
                } ?: error("Unable to open input stream")
            } ?: error("Unable to open output stream")

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                values.clear()
                values.put(MediaStore.MediaColumns.IS_PENDING, 0)
                contentResolver.update(out, values, null, null)
            }
            out
        } catch (t: Throwable) {
            // Clean up incomplete item if something fails
            try { contentResolver.delete(out, null, null) } catch (_: Throwable) {}
            throw t
        }
    }

    private fun shareImage(uri: Uri) {
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "image/*"
            putExtra(Intent.EXTRA_STREAM, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        startActivity(Intent.createChooser(intent, "Share PNG"))
    }

    private fun queryDisplayName(uri: Uri): String? {
        val projection = arrayOf(MediaStore.MediaColumns.DISPLAY_NAME)
        contentResolver.query(uri, projection, null, null, null)?.use { c ->
            val i = c.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME)
            if (c.moveToFirst()) return c.getString(i)
        }
        return null
    }
}

/** Rounded card containing a checkerboard background with optional overlay content. */
@Composable
private fun CheckerboardCard(
    height: Dp,
    cell: Dp = 12.dp,
    content: @Composable BoxScope.() -> Unit
) {
    Card(shape = RoundedCornerShape(16.dp)) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(height)
        ) {
            CheckerboardBackground(cell)
            content()
        }
    }
}

/** Light/dark checkerboard often used to visualize transparency. */
@Composable
private fun CheckerboardBackground(cell: Dp = 12.dp) {
    val light = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.7f)
    val dark = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.08f)
    Canvas(modifier = Modifier.fillMaxSize()) {
        val s = cell.toPx()
        var y = 0f
        var r = 0
        while (y < size.height) {
            var x = 0f
            var c = 0
            while (x < size.width) {
                drawRect(
                    color = if ((r + c) % 2 == 0) light else dark,
                    topLeft = Offset(x, y),
                    size = Size(minOf(s, size.width - x), minOf(s, size.height - y))
                )
                x += s
                c++
            }
            y += s
            r++
        }
    }
}

@Preview(showBackground = true)
@Composable
fun GreetingPreview() {
    BenintegrationTheme {
        Text("BEN Demo")
    }
}
