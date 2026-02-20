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
    'Harry Potter and the Sorcerer\'s Stone',
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

    // Small delay to show loading animation (feels more “real”)
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

  Widget _buildResultItem(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.menu_book),
          title: Text(title),
          subtitle: const Text('Tap to view (demo)'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Tapped: $title')),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResults() {
    Widget content;

    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_results.isEmpty) {
      content = Center(
        child: Text(
          _query.isEmpty
              ? 'Start typing to search for books.'
              : 'No results found for "$_query".',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    } else {
      content = ListView.builder(
        key: ValueKey(_results.length),
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
                offset: Offset(0, (1 - t) * 8),
                child: child,
              ),
            ),
            child: _buildResultItem(item),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search books...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                    _runSearch('');
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              onChanged: _runSearch,
            ),
          ),
          _buildResults(),
        ],
      ),
    );
  }
}