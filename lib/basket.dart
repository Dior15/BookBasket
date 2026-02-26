import 'package:flutter/material.dart';
import 'package:epub_parser/epub_parser.dart' hide Image;
import 'package:path/path.dart' as p;

import 'animations/app_page_route.dart';
import 'animations/staggered_in.dart';
import 'animations/book_card.dart';
import 'animations/book_details_page.dart';
import 'ereader/epub_loader.dart';

class Basket extends StatefulWidget {
  const Basket({super.key});

  @override
  State<StatefulWidget> createState() => BasketState();
}

class BasketState extends State<Basket> {
  final List<String> _items =
  [
    "An Omega For Dylan.epub",
    "gunslinger.epub",
    "My Baby Mama Is A Loser.epub",
    "Under The Dome.epub",
  ];

  void _openDetails(String title, Color color, String heroTag) {
    Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => BookDetailsPage(
          title: title,
          color: color,
          heroTag: heroTag,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const cardColor = Color.fromARGB(255, 138, 101, 236);

    return GridView.builder(
        padding: const EdgeInsets.all(10.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.6,
        ),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final title = _items[index];
          final heroTag = "basket-$index";

          // List<int> bytes = targetFile.readAsBytes();


          // Opens a book and reads all of its content into memory
//           EpubBook epubBook = await EpubReader.readBook(bytes);

          return BookCard(
            title: title,
            color: cardColor,
            heroTag: heroTag,
            onTap: () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => EpubLoaderPage(epubAssetPath: "assets/books/${_items[index]}",))
            ),
          );
        },

    );
  }
}