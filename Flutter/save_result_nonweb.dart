import 'dart:io' show File, Platform;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

Future<void> saveResultBytes(BuildContext context, Uint8List bytes, String baseName) async {
  // Mobile: save to Photos/Gallery
  if (Platform.isAndroid || Platform.isIOS) {
    final res = await ImageGallerySaver.saveImage(
      bytes,
      name: '${baseName}_cutout',
      quality: 100,
    );
    final ok = (res is Map && (res['isSuccess'] == true || res['isSuccess'] == 'true'));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Saved to gallery' : 'Saved (check Photos)')),
      );
    }
    return;
  }

  // Desktop: save to Downloads
  final downloads = Platform.isMacOS || Platform.isLinux
      ? '${Platform.environment['HOME']}/Downloads'
      : Platform.isWindows
          ? '${Platform.environment['USERPROFILE']}\\Downloads'
          : '.';

  final path = Platform.isWindows
      ? '$downloads\\${baseName}_cutout.png'
      : '$downloads/${baseName}_cutout.png';

  final file = File(path);
  await file.writeAsBytes(bytes);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved: $path')));
  }
}
