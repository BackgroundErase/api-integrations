import 'dart:convert';
import 'dart:io' show File, Platform;
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

/// Small helper to guess a content type from filename
MediaType _guessContentType(String filename) {
  final ext = p.extension(filename).toLowerCase();
  switch (ext) {
    case '.png':
      return MediaType('image', 'png');
    case '.jpg':
    case '.jpeg':
      return MediaType('image', 'jpeg');
    case '.webp':
      return MediaType('image', 'webp');
    case '.bmp':
      return MediaType('image', 'bmp');
    case '.tiff':
    case '.tif':
      return MediaType('image', 'tiff');
    case '.heic':
      // If your API accepts HEIC directly, keep this; otherwise convert on-device first.
      return MediaType('image', 'heic');
    default:
      return MediaType('application', 'octet-stream');
  }
}

class BenClient {
  BenClient({required this.apiKey});

  final String apiKey;

  static const _host = 'api.backgrounderase.net';
  static const _path = '/v2';

  /// Upload a file from a filesystem path. Returns result bytes (PNG or same type),
  /// or throws [BenClientException] on non-200.
  Future<Uint8List> removeBackgroundFromPath(String path,
      {String? overrideFilename, MediaType? overrideContentType}) async {
    final filename = overrideFilename ?? p.basename(path);
    final contentType = overrideContentType ?? _guessContentType(filename);

    final req = http.MultipartRequest('POST', Uri.https(_host, _path))
      ..headers['x-api-key'] = apiKey
      ..files.add(await http.MultipartFile.fromPath(
        'image_file',
        path,
        filename: filename,
        contentType: contentType,
      ));

    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode == 200) {
      return resp.bodyBytes;
    } else {
      // Try to decode JSON error; otherwise pass text as-is.
      String reason;
      try {
        final jsonMap = jsonDecode(utf8.decode(resp.bodyBytes)) as Map;
        reason = jsonMap['error']?.toString() ??
            jsonMap['message']?.toString() ??
            resp.reasonPhrase ??
            'Unknown error';
      } catch (_) {
        reason = utf8.decode(resp.bodyBytes, allowMalformed: true);
      }
      throw BenClientException(
        status: resp.statusCode,
        reason: reason,
      );
    }
  }

  /// Upload from memory (e.g., camera/web file picker).
  /// Provide a filename to set the content-type appropriately.
  Future<Uint8List> removeBackgroundFromBytes(
    Uint8List data, {
    required String filenameHint,
    MediaType? overrideContentType,
  }) async {
    final contentType = overrideContentType ?? _guessContentType(filenameHint);

    final req = http.MultipartRequest('POST', Uri.https(_host, _path))
      ..headers['x-api-key'] = apiKey
      ..files.add(http.MultipartFile.fromBytes(
        'image_file',
        data,
        filename: filenameHint,
        contentType: contentType,
      ));

    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode == 200) {
      return resp.bodyBytes;
    } else {
      String reason;
      try {
        final jsonMap = jsonDecode(utf8.decode(resp.bodyBytes)) as Map;
        reason = jsonMap['error']?.toString() ??
            jsonMap['message']?.toString() ??
            resp.reasonPhrase ??
            'Unknown error';
      } catch (_) {
        reason = utf8.decode(resp.bodyBytes, allowMalformed: true);
      }
      throw BenClientException(
        status: resp.statusCode,
        reason: reason,
      );
    }
  }
}

class BenClientException implements Exception {
  BenClientException({required this.status, required this.reason});
  final int status;
  final String reason;

  @override
  String toString() => 'BenClientException($status): $reason';
}
