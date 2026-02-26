import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'epub_reader_view.dart';

class EpubLoaderPage extends StatelessWidget {
  final String epubAssetPath;

  const EpubLoaderPage({super.key, required this.epubAssetPath});

  Future<Uint8List> _loadEpub() async {
    final data = await rootBundle.load(epubAssetPath);
    return data.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _loadEpub(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return EpubReaderPage(epubBytes: snapshot.data!);
      },
    );
  }
}
