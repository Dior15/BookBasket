import 'package:epub_parser/epub_parser.dart' hide Image;
import 'package:flutter/services.dart';


mixin CoverLoader {
  final Map<String, Uint8List?> _coverCache = {};

  Future<Uint8List?> loadEpubCover(String fileName) async {
    if (_coverCache.containsKey(fileName)) {
      return _coverCache[fileName];
    }

    try {
      final assetPath = 'assets/books/$fileName';
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      final book = await EpubReader.readBook(bytes);

      _coverCache[fileName] = book.CoverImage;
      return book.CoverImage;
    } catch (e) {
      // print('Error loading cover for $fileName: $e');
      _coverCache[fileName] = null;
      return null;
    }
  }
}