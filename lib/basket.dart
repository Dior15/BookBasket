import 'package:flutter/material.dart';
import 'package:epub_parser/epub_parser.dart' hide Image;
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

import 'animations/app_page_route.dart';
import 'animations/staggered_in.dart';
import 'animations/book_card.dart';
import 'animations/book_details_page.dart';
import 'ereader/epub_loader.dart';
import 'database/db.dart';
import 'auth_service.dart';
import 'map/reading_marker.dart';

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
    BasketContentManager.items = await db.getBasketContents(await AuthService.getEmail() as String);
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

  Widget _basketHero(int count) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A237E),
            Color(0xFF3949AB),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Basket',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count book${count == 1 ? '' : 's'} ready to read',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.shopping_basket_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Future<void> _saveReadingLocation(String bookTitle) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );

      final prefs = await SharedPreferences.getInstance();
      final markerStrings = prefs.getStringList('reading_markers')?.toList() ?? [];

      // Convert saved strings back into Marker objects
      List<ReadingMarker> existingMarkers = markerStrings.map((m) => ReadingMarker.fromJson(m)).toList();

      bool locationFound = false;

      // Check if we are within ~1km of an existing marker
      for (int i = 0; i < existingMarkers.length; i++) {
        final marker = existingMarkers[i];

        if ((marker.latitude - position.latitude).abs() < 0.01 &&
            (marker.longitude - position.longitude).abs() < 0.01) {

          locationFound = true; // We found a nearby marker!

          // Check if this book is already in this marker's list
          if (!marker.bookTitles.contains(bookTitle)) {
            marker.bookTitles.add(bookTitle); // Add the new book
            existingMarkers[i] = marker; // Update the list
            debugPrint("SUCCESS: Added '$bookTitle' to existing marker at ${marker.latitude}, ${marker.longitude}");
          } else {
            debugPrint("IGNORED: '$bookTitle' is already recorded at this location.");
          }
          break; // Stop checking other markers
        }
      }

      // If no marker was within 1km, create a brand new one
      if (!locationFound) {
        final newMarker = ReadingMarker(
          bookTitles: [bookTitle],
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: DateTime.now(),
        );
        existingMarkers.add(newMarker);
        debugPrint("SUCCESS: Created NEW marker for '$bookTitle' at ${position.latitude}, ${position.longitude}");
      }

      // Save the updated list back to SharedPreferences
      final updatedMarkerStrings = existingMarkers.map((m) => m.toJson()).toList();
      await prefs.setStringList('reading_markers', updatedMarkerStrings);

    } catch (e) {
      debugPrint('Location save failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // const cardColor = Color.fromARGB(255, 138, 101, 236);
    const cardColor = Color.fromARGB(10, 0, 0, 0);

    return Column(
      children: [
        _basketHero(BasketContentManager.items.length),
        Expanded(
          child: BasketContentManager.items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF3949AB).withOpacity(0.10),
                        ),
                        child: const Icon(
                          Icons.shopping_basket_outlined,
                          color: Color(0xFF3949AB),
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Your basket is empty',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.6666,
                  ),
                  itemCount: BasketContentManager.items.length,
                  itemBuilder: (context, index) {
                    final title = BasketContentManager.items[index];
                    final heroTag = "basket-$index";

          // List<int> bytes = targetFile.readAsBytes();


          // Opens a book and reads all of its content into memory
//           EpubBook epubBook = await EpubReader.readBook(bytes);

                    return GestureDetector(
                      onLongPressStart: (details) {
                        showMenu(
                          context: context,
                          position: RelativeRect.fromLTRB(
                            details.globalPosition.dx,
                            details.globalPosition.dy,
                            details.globalPosition.dx,
                            details.globalPosition.dy,
                          ),
                          items: [
                            PopupMenuItem(
                              value: "return",
                              child: Text("Return ${title.substring(0, title.length - 5)}"),
                            )
                          ],
                        ).then((value) async {
                          if (value == "return") {
                            DB db = await DB.getReference();
                            await db.checkInBook(await AuthService.getEmail() as String, title);
                            await context.read<BasketContentManager>().reload();
                            setState(() {});
                          }
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Theme.of(context).colorScheme.surface,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
                          ),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: BookCard(
                          title: title,
                          color: cardColor,
                          heroTag: heroTag,
                          onTap: () {
                            _saveReadingLocation(title);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EpubLoaderPage(
                                      epubAssetPath: "assets/books/${BasketContentManager
                                          .items[index]}",
                                    ),
                              ),
                            );
                          }
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// This class can be triggered as a ChangeNotifier to refresh the displayed content in the basket when it has been changed
class BasketContentManager extends ChangeNotifier {
  static List<String> items = [];

  Future<void> reload() async {
    DB db = await DB.getReference();
    items = await db.getBasketContents(await AuthService.getEmail() as String);
    notifyListeners();
  }
}
