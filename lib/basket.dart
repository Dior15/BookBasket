import 'package:flutter/material.dart';
import 'package:epub_parser/epub_parser.dart' hide Image;
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'animations/app_page_route.dart';
import 'animations/staggered_in.dart';
import 'animations/book_card.dart';
import 'animations/book_details_page.dart';
import 'ereader/epub_loader.dart';
import 'database/db.dart';
import 'auth_service.dart';
import 'firebase_database/firebase_db.dart';
import 'map/reading_marker.dart';

class Basket extends StatefulWidget {
  const Basket({super.key});

  @override
  State<StatefulWidget> createState() => BasketState();
}

class BasketState extends State<Basket> {
  @override
  void initState() {
    super.initState();
    getBookFileNames();
  }

  // This needs to be called outside of initState because initState cannot be an async method itself
  void getBookFileNames() async {
    FirebaseDB db = FirebaseDB.getReference();
    BasketContentManager.items = db.getBasketContents(await AuthService.getEmail() as String);
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

  // --- MERGED: Uses FirebaseDB instead of SharedPreferences for Map Markers ---
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

      final email = await AuthService.getEmail() ?? AuthService.userEmail;
      final db = FirebaseDB.getReference();

      // 1. Fetch existing cloud markers for this user
      List<ReadingMarker> existingMarkers = await db.getUserMarkers(email);

      bool locationFound = false;

      // 2. Check if we are within ~1km of an existing cloud marker
      for (int i = 0; i < existingMarkers.length; i++) {
        final marker = existingMarkers[i];

        if ((marker.latitude - position.latitude).abs() < 0.01 &&
            (marker.longitude - position.longitude).abs() < 0.01) {

          locationFound = true;

          // 3. Check if this book is already in this marker's list
          if (!marker.bookTitles.contains(bookTitle)) {

            // Delete the old marker from the cloud
            await db.deleteUserMarker(email, marker);

            // Update the data locally, then upload the updated version as a new marker
            marker.bookTitles.add(bookTitle);
            await db.addUserMarker(email, marker);

            debugPrint("SUCCESS: Added '$bookTitle' to existing cloud marker at ${marker.latitude}, ${marker.longitude}");
          } else {
            debugPrint("IGNORED: '$bookTitle' is already recorded at this cloud location.");
          }
          break;
        }
      }

      // 4. If no marker was within 1km, create a brand new one in the cloud
      if (!locationFound) {
        final newMarker = ReadingMarker(
          bookTitles: [bookTitle],
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: DateTime.now(),
        );

        await db.addUserMarker(email, newMarker);
        debugPrint("SUCCESS: Created NEW cloud marker for '$bookTitle' at ${position.latitude}, ${position.longitude}");
      }

    } catch (e) {
      debugPrint('Location save failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const cardColor = Color.fromARGB(10, 0, 0, 0);

    return FutureBuilder(
        future: BasketContentManager.items,
        builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          List<Map<String, dynamic>>? items = [];

          if (snapshot.connectionState == ConnectionState.waiting) {
            items = [];
          } else if (snapshot.hasData) {
            items = snapshot.data;
          }

          return Column(
              children: [
                _basketHero(items == null ? 0 : items.length),
                Expanded(
                    child: items == null ? const Text("Failed to load basket") : items.isEmpty
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
                    ) :
                    MasonryGridView.count(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final title = items == null ? "" : items[index]["fileName"];
                          final heroTag = "basket-$index";

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
                                  FirebaseDB db = FirebaseDB.getReference();
                                  await db.checkInBook(await AuthService.getEmail() as String, title);
                                  await context.read<BasketContentManager>().reload();
                                  setState(() {});
                                }
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: Colors.black.withOpacity(0.18),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
                                ),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Column(
                                children: [
                                  BookCard(
                                    title: title as String,
                                    color: cardColor,
                                    heroTag: heroTag,
                                    onTap: () {
                                      _saveReadingLocation(title);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              EpubLoaderPage(
                                                epubAssetPath:
                                                items == null ?
                                                "" :
                                                "assets/books/${items[index]["fileName"]}",
                                              ),
                                        ),
                                      );
                                    },
                                    coverPath: items == null ? ""  : items[index]["fileName"]!.length < 5 ? "" : "assets/book_covers/${items[index]["fileName"]?.substring(0, items[index]["fileName"]!.length - 5)}.jpg",
                                  ),
                                  const SizedBox(height: 3),
                                  Text("Expires on: ${items?[index]["checkoutExpiry"]}"),
                                  const SizedBox(height: 3),
                                ],
                              ),
                            ),
                          );
                        }
                    )

                )
              ]
          );
        }
    );
  }
}

/// This class can be triggered as a ChangeNotifier to refresh the displayed content in the basket when it has been changed
class BasketContentManager extends ChangeNotifier {
  static Future<List<Map<String, dynamic>>> items = Future.value([]);

  Future<void> reload() async {
    FirebaseDB db = FirebaseDB.getReference();
    items = db.getBasketContents(await AuthService.getEmail() as String);

    notifyListeners();
  }
}