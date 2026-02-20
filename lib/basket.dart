import 'package:flutter/material.dart';

import 'animations/app_page_route.dart';
import 'animations/staggered_in.dart';
import 'animations/book_card.dart';
import 'animations/book_details_page.dart';

class Basket extends StatefulWidget {
  const Basket({super.key});

  @override
  State<StatefulWidget> createState() => BasketState();
}

class BasketState extends State<Basket> {
  final List<String> _items = List.generate(15, (i) => "Title ${i + 1}");

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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Your Basket"),
      ),
      body: GridView.builder(
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

          return StaggeredIn(
            index: index,
            child: BookCard(
              title: title,
              color: cardColor,
              heroTag: heroTag,
              onTap: () => _openDetails(title, cardColor, heroTag),
            ),
          );
        },
      ),
    );
  }
}