import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'ereader/epub_reader_view.dart';

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  Future<Uint8List> _loadEpub() async {
    print("Loading");
    final bytes = await rootBundle.load('assets/Twelve Angry Men.epub');
    print("Loaded bytes: ${bytes.lengthInBytes}");
    return bytes.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EPUBX Reader Test',
      home: FutureBuilder<Uint8List>(
        future: _loadEpub(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return EpubReaderPage(epubBytes: snapshot.data!);
        },
      ),
    );
  }
}