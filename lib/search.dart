import 'package:flutter/material.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final TextEditingController _searchCtrl = TextEditingController();

  String _query = '';
  bool _isLoading = false;
  List<String> _results = const [];

  // Demo data (replace with real backend/db results later)
  final List<String> _allBooks = const [
    'The Great Gatsby',
    'To Kill a Mockingbird',
    '1984',
    'Pride and Prejudice',
    'The Catcher in the Rye',
    'The Hobbit',
    'Fahrenheit 451',
    'Moby-Dick',
    'Brave New World',
    'Jane Eyre',
    'The Alchemist',
    'The Book Thief',
    'The Hunger Games',
    'Dune',
    "Harry Potter and the Sorcerer's Stone",
  ];

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
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String value) async {
    final q = value.trim();
    setState(() {
      _query = q;
      _isLoading = true;
    });

    // Small delay to show loading animation (feels more "real")
    await Future.delayed(const Duration(milliseconds: 250));

    if (q.isEmpty) {
      setState(() {
        _results = const [];
        _isLoading = false;
      });
      return;
    }

    final lowered = q.toLowerCase();
    final filtered = _allBooks
        .where((b) => b.toLowerCase().contains(lowered))
        .toList(growable: false);

    setState(() {
      _results = filtered;
      _isLoading = false;
    });
  }

  Widget _buildResultItem(String title, int index) {
    final accent = _accentColors[index % _accentColors.length];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).cardColor,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Tapped: $title'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
                      const SizedBox(height: 3),
                      Text(
                        'Tap to view details',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
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
                : 'Try a different search term',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    Widget content;

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    } else if (_results.isEmpty) {
      content = _buildEmptyState();
    } else {
      content = ListView.builder(
        key: ValueKey(_results.length),
        padding: const EdgeInsets.only(top: 4, bottom: 20),
        itemCount: _results.length,
        itemBuilder: (context, index) {
          final item = _results[index];
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
            child: _buildResultItem(item, index),
          );
        },
      );
    }

    return Expanded(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: content,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Search header banner ───────────────────────────────────────────
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
              // ── Search field ───────────────────────────────────────────
              Material(
                elevation: 6,
                shadowColor: Colors.black26,
                borderRadius: BorderRadius.circular(14),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Title, author, keyword...',
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
                              _runSearch('');
                            },
                          ),
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
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
                  onChanged: _runSearch,
                ),
              ),
            ],
          ),
        ),
        // ── Results count label ────────────────────────────────────────────
        if (_results.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Text(
              '${_results.length} result${_results.length == 1 ? '' : 's'}',
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
