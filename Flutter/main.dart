import 'dart:io' show File, Platform;
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'save_result_nonweb.dart'
  if (dart.library.html) 'save_result_web.dart';

import 'ben_client.dart';

/// ── SET YOUR API KEY HERE ────────────────────────────────────────────────────
const String kBenApiKey = 'YOUR_API_KEY_HERE';
/// ─────────────────────────────────────────────────────────────────────────────

void main() {
  runApp(const BENApp());
}

class BENApp extends StatelessWidget {
  const BENApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BEN Background Removal Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const BenHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class BenHomePage extends StatefulWidget {
  const BenHomePage({super.key});

  @override
  State<BenHomePage> createState() => _BenHomePageState();
}
class Checkerboard extends StatelessWidget {
  const Checkerboard({super.key, required this.child, this.radius = 16});
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CustomPaint(
        painter: _CheckerPainter(),
        child: child,
      ),
    );
  }
}

class _CheckerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cell = 16.0;
    final light = Paint()..color = const Color(0xFFEDEDED);
    final dark  = Paint()..color = const Color(0xFFD9D9D9);
    for (double y = 0; y < size.height; y += cell) {
      for (double x = 0; x < size.width; x += cell) {
        final isDark = (((x / cell).floor() + (y / cell).floor()) % 2) == 0;
        canvas.drawRect(Rect.fromLTWH(x, y, cell, cell), isDark ? dark : light);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}



class _BenHomePageState extends State<BenHomePage> {
  final _client = BenClient(apiKey: kBenApiKey);

  String? _pickedPath;
  String? _pickedName;
  Uint8List? _pickedBytes;

  Uint8List? _resultBytes;
  bool _isLoading = false;
  String? _error;

  Future<void> _pickImage() async {
    setState(() {
      _error = null;
      _resultBytes = null;
    });

    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'bmp', 'tiff', 'tif', 'heic'],
      withData: kIsWeb, // On web we want bytes
    );

    if (res == null || res.files.isEmpty) return;

    final file = res.files.first;
    _pickedName = file.name;

    if (kIsWeb) {
      _pickedBytes = file.bytes;
      _pickedPath = null;
    } else {
      _pickedPath = file.path;
      _pickedBytes = null;
    }
    setState(() {});
  }

  Future<void> _runRemoval() async {
    if (_pickedPath == null && _pickedBytes == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _resultBytes = null;
    });

    try {
      Uint8List out;
      if (_pickedBytes != null && _pickedName != null) {
        out = await _client.removeBackgroundFromBytes(
          _pickedBytes!,
          filenameHint: _pickedName!,
        );
      } else {
        out = await _client.removeBackgroundFromPath(_pickedPath!);
      }
      setState(() => _resultBytes = out);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _previewBox({required String title, required Widget child}) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.all(8),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Center(child: child),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

Future<void> _saveResult() async {
  if (_resultBytes == null) return;
  final base = (_pickedName ?? 'ben_output').replaceAll(RegExp(r'\.\w+$'), '');
  await saveResultBytes(context, _resultBytes!, base);
}


@override
Widget build(BuildContext context) {
  final hasInput = _pickedPath != null || _pickedBytes != null;
  final fileLabel = _pickedName ?? 'No file selected';

  return Scaffold(
    appBar: AppBar(
      title: const Text('BEN Background Removal'),
      centerTitle: false,
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiny filename header under the app bar
            Text(
              fileLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                  ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 12),

            // Top controls: use Wrap so it never overflows
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.start,
              children: [
                FilledButton.icon(
                  onPressed: _isLoading ? null : _pickImage,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Files'),
                ),
                // Optional: a second "Photos" button could open an image picker for camera roll.
                // For now it calls _pickImage too.
                FilledButton.icon(
                  onPressed: _isLoading ? null : _pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Photos'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Big full-width action button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isLoading || !hasInput ? null : _runRemoval,
                icon: const Icon(Icons.content_cut),
                label: const Text('Remove Background'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            if (_isLoading) const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 16),

            // Responsive previews: column on phones, row on wide screens
            LayoutBuilder(
              builder: (context, c) {
                final isWide = c.maxWidth >= 700;
                final children = <Widget>[
                  _previewCard(
                    title: 'Original',
                    child: Builder(
                      builder: (_) {
                        if (!hasInput) return const Text('No image selected');
                        if (kIsWeb && _pickedBytes != null) {
                          return Image.memory(_pickedBytes!, fit: BoxFit.contain);
                        }
                        if (_pickedPath != null) {
                          return Image.file(File(_pickedPath!), fit: BoxFit.contain);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  _previewCard(
                    title: 'Result (PNG w/ transparency)',
                    child: _resultBytes == null
                        ? const Text('No result yet')
                        : Checkerboard(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.memory(_resultBytes!, fit: BoxFit.contain),
                            ),
                          ),
                  ),
                ];

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: children
                        .map((w) => Expanded(child: w))
                        .toList(growable: false),
                  );
                }
                return Column(children: children);
              },
            ),

            const SizedBox(height: 12),

            // Save button (full width) — only visible when we have a result
            if (_resultBytes != null)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _saveResult,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text('Save to Photos'),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

// Small helper to style preview sections as cards with fixed height
Widget _previewCard({required String title, required Widget child}) {
  return Card(
    elevation: 1.5,
    margin: const EdgeInsets.symmetric(vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          SizedBox(
            height: 320, // good phone default; still scrollable overall
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(14),
                color: Colors.white,
              ),
              child: Center(child: child),
            ),
          ),
        ],
      ),
    ),
  );
}




}
