import 'package:flutter/material.dart';

class BookDetailsPage extends StatelessWidget {
  final String title;
  final Color color;
  final String heroTag;

  const BookDetailsPage({
    super.key,
    required this.title,
    required this.color,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: Hero(
                tag: heroTag,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    color: color,
                    child: Center(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AnimatedOpacity(
              opacity: 1,
              duration: const Duration(milliseconds: 450),
              child: Text(
                'Details page placeholder for "$title".\n\n'
                    'This is where your description, author, rating, and Add to Basket button would go.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}