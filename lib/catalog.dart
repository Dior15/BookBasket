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
        child: Text(text, style: const TextStyle(fontSize: 20)),
      ),
    );
  }

  // ── Hero banner at the top ────────────────────────────────────────────────
  Widget _heroBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A237E), // deep indigo
            Color(0xFF283593),
            Color(0xFF3949AB),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.4),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // decorative circles
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            left: -10,
            bottom: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'Welcome to BookBasket',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Discover your next great read',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 20,
            top: 0,
            bottom: 0,
            child: Align(
              alignment: Alignment.centerRight,
              child: Icon(
                Icons.auto_stories_rounded,
                size: 54,
                color: Colors.white.withOpacity(0.18),
              ),
            ),
          ),
        ],
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
                child: BookCard(
                  title: title,
                  color: color,
                  heroTag: heroTag,
                  onTap: () => _openDetails(title, color, heroTag),
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
            _heroBanner(),
            _sectionTitle("This Week's Featured"),
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