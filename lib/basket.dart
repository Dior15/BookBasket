import 'package:flutter/material.dart';
import 'package:epub_parser/epub_parser.dart' hide Image;
import 'package:path/path.dart' as p;

import 'animations/app_page_route.dart';
import 'animations/staggered_in.dart';
import 'animations/book_card.dart';
import 'animations/book_details_page.dart';
import 'ereader/epub_loader.dart';
import 'database/db.dart';

class Basket extends StatefulWidget {
  const Basket({super.key});

  @override
  State<StatefulWidget> createState() => BasketState();
}

class BasketState extends State<Basket> {
  // late List<String> _items = [];
  // [
  //   "The Gunslinger.epub",
  //   "It Ends With Us.epub",
  //   "Camp X.epub",
  //   "Fantastic 4 Rise of the Silver Surfer.epub",
  //   "My Baby Mama Is A Loser.epub",
  //   "Cruel Mate.epub",
  //   "Twelve Angry Men.epub",
  //   "An Omega For Dylan.epub",
  //   "Under The Dome.epub",
  //   "Sisters.epub",
  // ];

  @override
  void initState() {
    super.initState();
    getBookFileNames();
  }

  // This needs to be called outside of initState because initState cannot be an async method itself
  void getBookFileNames() async {
    DB db = await DB.getReference();
    BasketContentManager.items = await db.getBookFileNames();
    // setState(() {});
  }

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
    // const cardColor = Color.fromARGB(255, 138, 101, 236);
    const cardColor = Color.fromARGB(10, 0, 0, 0);

    return GridView.builder(
        padding: const EdgeInsets.all(10.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.6666,
        ),
        itemCount: BasketContentManager.items.length,
        itemBuilder: (context, index) {
          final title = BasketContentManager.items[index];
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
              MaterialPageRoute(builder: (_) => EpubLoaderPage(epubAssetPath: "assets/books/${BasketContentManager.items[index]}",))
            ),
          );
        },

    );
  }
}

/// This class can be triggered as a ChangeNotifier to refresh the displayed content in the basket when it has been changed
class BasketContentManager extends ChangeNotifier {
  static List<String> items = [];

  Future<void> reload() async {
    DB db = await DB.getReference();
    items = await db.getBookFileNames();
    notifyListeners();
  }
}
