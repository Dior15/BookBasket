import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../basket.dart';
import '../ereader/cover_loader.dart';
import '../auth_service.dart';
import '../firebase_database/firebase_db.dart';

class BookDetailsPage extends StatefulWidget {
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
  State<BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> with CoverLoader {
  // ── State ────────────────────────────────────────────────────────────────
  int? _userRating;      // null = not rated yet
  double? _avgRating;    // null = no ratings at all
  bool _loadingRating = true;
  bool _savingRating = false;
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    final email = await AuthService.getEmail();
    if (!mounted) return;
    setState(() => _username = email);

    final db = FirebaseDB.getReference();
    final results = await Future.wait<dynamic>([
      db.getUserRating(email!, widget.title),
      db.getAverageRating(widget.title),
    ]);

    if (!mounted) return;
    setState(() {
      _userRating = results[0] as int?;
      _avgRating  = results[1] as double?;
      _loadingRating = false;
    });
  }

  Future<void> _setRating(int stars) async {
    if (_username == null || _savingRating) return;

    final removing = stars == _userRating; // tapped the already-selected star
    setState(() {
      _savingRating = true;
      _userRating = removing ? null : stars; // optimistic update
    });

    final db = FirebaseDB.getReference();
    if (removing) {
      await db.deleteUserRating(_username!, widget.title);
    } else {
      await db.setUserRating(_username!, widget.title, stars);
    }

    // Refresh the average after saving
    final newAvg = await db.getAverageRating(widget.title);
    if (!mounted) return;
    setState(() {
      _avgRating = newAvg;
      _savingRating = false;
    });
  }

  // ── Widgets ───────────────────────────────────────────────────────────────
  Widget _starRatingSection() {
    return Column(
      children: [
        // ── User interactive stars ───────────────────────────────────────
        Text(
          'Your Rating',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
        ),
        const SizedBox(height: 6),
        _loadingRating
            ? const SizedBox(
                height: 36,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final starValue = i + 1;
                  final filled = _userRating != null && starValue <= _userRating!;
                  return GestureDetector(
                    onTap: _savingRating ? null : () => _setRating(starValue),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        filled ? Icons.star_rounded : Icons.star_outline_rounded,
                        key: ValueKey('$starValue-$filled'),
                        color: filled
                            ? const Color(0xFFFFC107)
                            : Colors.grey.shade400,
                        size: 38,
                      ),
                    ),
                  );
                }),
              ),
        const SizedBox(height: 4),
        if (!_loadingRating)
          Text(
            _userRating == null
                ? 'Tap to rate'
                : '${_userRating!} / 5',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
          ),

        const SizedBox(height: 16),

        // ── Global average ───────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people_outline_rounded,
                  size: 18, color: Colors.grey),
              const SizedBox(width: 6),
              _loadingRating
                  ? const SizedBox(
                      width: 60,
                      height: 14,
                      child: LinearProgressIndicator(),
                    )
                  : Text(
                      _avgRating == null
                          ? 'No ratings yet'
                          : 'Community: ${_avgRating!.toStringAsFixed(1)} / 5',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayTitle = widget.title.substring(0, widget.title.length - 5);
    return Scaffold(
      appBar: AppBar(title: Text(displayTitle)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 14),
            // ── Cover image ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Hero(
                  tag: widget.heroTag,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      color: widget.color,
                      child: Center(
                        child: FutureBuilder<Uint8List?>(
                          future: loadEpubCover(widget.title),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const SizedBox(
                                child: Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                              );
                            }
                            final cover = snapshot.data;
                            if (cover == null) {
                              return const SizedBox(
                                width: 80,
                                height: 120,
                                child: Center(
                                  child: Text('No cover',
                                      style:
                                          TextStyle(color: Colors.white)),
                                ),
                              );
                            }
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              // child: Image.memory(cover, fit: BoxFit.cover),
                              child: Image.asset("assets/book_covers/${widget.title.substring(0, widget.title.length - 5)}.jpg")
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Star rating section ───────────────────────────────────────
            _starRatingSection(),

            const SizedBox(height: 20),

            // ── Checkout button ───────────────────────────────────────────
            TextButton(
              onPressed: () async {
                final email = await AuthService.getEmail();
                final db = FirebaseDB.getReference();
                final checkoutID =
                    await db.checkOutBook(email!, widget.title);
                if (!context.mounted) return;
                if (checkoutID == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$displayTitle is unavailable right now.'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Successfully checked out $displayTitle'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                if (!context.mounted) return;
                context.read<BasketContentManager>().reload();
              },
              child: Text('Checkout $displayTitle'),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}