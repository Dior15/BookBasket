import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../ereader/cover_loader.dart';

class BookDetailsPage extends StatelessWidget with CoverLoader{
  final String title;
  final Color color;
  final String heroTag;

  BookDetailsPage({
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
                      child: FutureBuilder<Uint8List?>(
                        future: loadEpubCover(title), // title = filename
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox(
                              child: Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2
                                ),
                              ),
                            );
                          }
                          final cover = snapshot.data;
                          if (cover == null) {
                            return const SizedBox(
                              width: 80,
                              height: 120,
                              child: Center(
                                child: Text(
                                  "No cover",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            );
                          }
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              cover,
                              fit: BoxFit.cover,
                            ),
                          );
                        },
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