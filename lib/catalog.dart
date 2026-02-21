import 'package:flutter/material.dart';
import 'animations/app_page_route.dart';
import 'animations/staggered_in.dart';
import 'animations/book_details_page.dart';
import 'animations/book_card.dart';

class Catalog extends StatefulWidget {
  const Catalog({super.key});

  @override
  State<StatefulWidget> createState() => CatalogState();
}

class CatalogState extends State<Catalog> {
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

  Widget _sectionTitle(String text) {
    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20.0, 5.0, 10.0, 5.0),
        child: Text(text, style: const TextStyle(fontSize: 24)),
      ),
    );
  }

  Widget _horizontalRow({
    required String prefix,
    required int count,
    required double height,
    required double width,
    required Color color,
  }) {
    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        padding: const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 5.0),
        itemBuilder: (context, index) {
          final title = "$prefix ${index + 1}";
          final heroTag = "$prefix-$index";

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: SizedBox(
              width: width,
              child: StaggeredIn(
                index: index,
                child: BookCard(
                  title: title,
                  color: color,
                  heroTag: heroTag,
                  onTap: () => _openDetails(title, color, heroTag),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Column(
          children: [
            _sectionTitle("This Week's Featured Books"),
            _horizontalRow(
              prefix: "Featured Title",
              count: 10,
              height: 300,
              width: 180,
              color: const Color.fromARGB(255, 0, 100, 255),
            ),
            const Divider(height: 20, thickness: 2, indent: 20, endIndent: 20),
            _sectionTitle("Recommended For You"),
            _horizontalRow(
              prefix: "Recommended Title",
              count: 10,
              height: 200,
              width: 120,
              color: const Color.fromARGB(255, 138, 101, 236),
            ),
            const Divider(height: 20, thickness: 2, indent: 20, endIndent: 20),
            _sectionTitle("Critically Acclaimed"),
            _horizontalRow(
              prefix: "Acclaimed Title",
              count: 10,
              height: 200,
              width: 120,
              color: const Color.fromARGB(255, 143, 239, 111),
            ),
            const SizedBox(height: 75),
          ],
        ),
    );
  }
}