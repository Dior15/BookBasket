import 'dart:async';
import 'package:flutter/material.dart';
import 'animations/app_page_route.dart';
import 'animations/book_details_page.dart';
import 'firebase_database/firebase_db.dart';

// ── Enums for filter & sort ──────────────────────────────────────────────────
enum AvailabilityFilter { all, available, borrowed }

enum SortOption { titleAZ, titleZA }

// ── Widget ───────────────────────────────────────────────────────────────────
class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  String _query = '';
  bool _isLoading = false;

  // Raw results from DB (unfiltered / unsorted)
  List<Map<String, Object?>> _rawResults = const [];
  // After filter + sort applied
  List<Map<String, Object?>> _displayResults = const [];

  // Filter & sort state
  AvailabilityFilter _filter = AvailabilityFilter.all;
  SortOption _sort = SortOption.titleAZ;

  // Accent colors cycling through results
  static const List<Color> _accentColors = [
    Color(0xFF3949AB),
    Color(0xFF8A65EC),
    Color(0xFF2E7D32),
    Color(0xFF0064FF),
    Color(0xFFBF360C),
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Search handling ────────────────────────────────────────────────────────

  void _onSearchChanged(String value) {
    final q = value.trim();
    _debounce?.cancel();

    if (q.isEmpty) {
      setState(() {
        _query = '';
        _rawResults = const [];
        _displayResults = const [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _query = q;
      _isLoading = true;
    });

    _debounce = Timer(const Duration(milliseconds: 300), () {
      _runSearch(q);
    });
  }

  Future<void> _runSearch(String q) async {
    final db = FirebaseDB.getReference();
    final matches = await db.getBooksByTitle(q);

    if (!mounted) return;
    if (_query != q) return;
    setState(() {
      _rawResults = matches;
      _displayResults = _applyFilterAndSort(matches);
      _isLoading = false;
    });
  }

  // ── Filter & sort logic ────────────────────────────────────────────────────

  List<Map<String, Object?>> _applyFilterAndSort(
    List<Map<String, Object?>> source,
  ) {
    // 1. Filter
    // isBorrowed is a bool from Firestore (true = borrowed, false = available)
    Iterable<Map<String, Object?>> filtered = source;
    if (_filter == AvailabilityFilter.available) {
      filtered = source.where((b) => b['isBorrowed'] == false);
    } else if (_filter == AvailabilityFilter.borrowed) {
      filtered = source.where((b) => b['isBorrowed'] == true);
    }

    // 2. Sort
    final list = filtered.toList();
    switch (_sort) {
      case SortOption.titleAZ:
        list.sort((a, b) => _str(a, 'title').compareTo(_str(b, 'title')));
        break;
      case SortOption.titleZA:
        list.sort((a, b) => _str(b, 'title').compareTo(_str(a, 'title')));
        break;
    }
    return list;
  }

  static String _str(Map<String, Object?> m, String key) =>
      (m[key]?.toString() ?? '').toLowerCase();

  void _setFilter(AvailabilityFilter f) {
    if (f == _filter) return;
    setState(() {
      _filter = f;
      _displayResults = _applyFilterAndSort(_rawResults);
    });
  }

  void _setSort(SortOption s) {
    if (s == _sort) return;
    setState(() {
      _sort = s;
      _displayResults = _applyFilterAndSort(_rawResults);
    });
  }

  // ── UI helpers ─────────────────────────────────────────────────────────────

  Widget _buildResultItem(Map<String, Object?> book, int index) {
    final title = book['title']?.toString() ?? '(unknown)';
    final fileName = book['fileName']?.toString() ?? '';
    final accent = _accentColors[index % _accentColors.length];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).cardColor,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final heroTag = 'search-$fileName';

            // 1. Clean the title to match how it's saved in the database
            String cleanTitle = fileName.replaceAll(".epub", "");

            // 2. Fetch both the AI summary and the availability date simultaneously
            final results = await Future.wait([
              FirebaseDB.getReference().getBookSummary(cleanTitle),
              FirebaseDB.getReference().getBookCheckoutExpiration(fileName),
            ]);

            String? summary = results[0];
            String? availableOn = results[1];

            // 3. Ensure the widget is still on screen before navigating
            if (!mounted) return;

            Navigator.of(context).push(
              AppPageRoute(
                builder: (_) => BookDetailsPage(
                  title: fileName,
                  color: const Color.fromARGB(10, 0, 0, 0),
                  heroTag: heroTag,
                  availableOn: availableOn, // <-- Colleague's feature added!
                  summary: summary ?? "No AI summary available. Tap the magic wand icon in the catalog to generate one!",
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: accent.withOpacity(0.18),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // colored left stripe
                Container(
                  width: 5,
                  height: 68,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.auto_stories_rounded,
                    color: accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: accent.withOpacity(0.6),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF3949AB).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_rounded,
              size: 36,
              color: Color(0xFF3949AB),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _query.isEmpty ? 'Search for a book' : 'No results for "$_query"',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _query.isEmpty
                ? 'Type a title, author, or keyword'
                : 'Try a different search term or filter',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    if (_displayResults.isEmpty) {
      return Expanded(child: _buildEmptyState());
    }

    final snapshot =
        List<Map<String, Object?>>.unmodifiable(_displayResults);
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 20),
        itemCount: snapshot.length,
        itemBuilder: (context, index) {
          final book = snapshot[index];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 220 + index * 60),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) => Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, (1 - t) * 10),
                child: child,
              ),
            ),
            child: _buildResultItem(book, index),
          );
        },
      ),
    );
  }

  // ── Filter & sort chip bar ─────────────────────────────────────────────────

  Widget _buildFilterSortBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // ── Availability filter chips ──
          _filterChip('All', AvailabilityFilter.all),
          const SizedBox(width: 6),
          _filterChip('Available', AvailabilityFilter.available),
          const SizedBox(width: 6),
          _filterChip('Borrowed', AvailabilityFilter.borrowed),
          const Spacer(),
          // ── Sort dropdown ───────────────
          _sortButton(),
        ],
      ),
    );
  }

  Widget _filterChip(String label, AvailabilityFilter value) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => _setFilter(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF3949AB)
              : const Color(0xFF3949AB).withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF3949AB),
          ),
        ),
      ),
    );
  }

  Widget _sortButton() {
    return PopupMenuButton<SortOption>(
      onSelected: _setSort,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 36),
      itemBuilder: (_) => const [
        PopupMenuItem(value: SortOption.titleAZ, child: Text('Title A → Z')),
        PopupMenuItem(value: SortOption.titleZA, child: Text('Title Z → A')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF3949AB).withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort_rounded, size: 16, color: Color(0xFF3949AB)),
            const SizedBox(width: 4),
            Text(
              _sortLabel(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3949AB),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _sortLabel() {
    switch (_sort) {
      case SortOption.titleAZ:
        return 'Title A-Z';
      case SortOption.titleZA:
        return 'Title Z-A';
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Search header banner ─────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1A237E),
                Color(0xFF3949AB),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Find Your Book',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Search across our full catalog',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              // ── Search field ───────────────────────────────────────────────
              Material(
                elevation: 6,
                shadowColor: Colors.black26,
                borderRadius: BorderRadius.circular(14),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(fontSize: 15, color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF3949AB),
                    ),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: Icon(
                              Icons.cancel_rounded,
                              color: Colors.grey.shade400,
                            ),
                            onPressed: () {
                              _searchCtrl.clear();
                              _onSearchChanged('');
                            },
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF3949AB),
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
            ],
          ),
        ),
        // ── Filter & sort bar ────────────────────────────────────────────────
        _buildFilterSortBar(),
        // ── Results count label ──────────────────────────────────────────────
        if (_displayResults.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(
              '${_displayResults.length} result${_displayResults.length == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        _buildResults(),
      ],
    );
  }
}
