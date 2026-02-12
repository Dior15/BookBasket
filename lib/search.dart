import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  bool _isLoading = false;
  // Placeholder for future results
  List<String> _results = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // This is a hook for when backend/search is wired up
  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _query = query;
    });

    // TODO: Replace with actual backend call
    await Future.delayed(const Duration(milliseconds: 600));

    // Placeholder: simulate results for now
    List<String> fauxResults = [];
    if (query.trim().isNotEmpty) {
      fauxResults = List.generate(
        6,
            (i) => 'Result ${i + 1} for "$query"',
      );
    }

    setState(() {
      _results = fauxResults;
      _isLoading = false;
    });
  }

  Widget _buildResultItem(String text) {
    // Basic list tile representing a result
    return ListTile(
      leading: const Icon(Icons.book),
      title: Text(text),
      subtitle: const Text('Bookbasket item placeholder'),
      onTap: () {
      // Hook for future detail navigation
      },
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      // Simple loading shimmer / progress indicator
      return const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_results.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            _query.isEmpty
                ? 'Start typing to search for books.'
                : 'No results yet. Implement backend to fetch results for "$_query".',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: _results.length,
        itemBuilder: (context, index) => _buildResultItem(_results[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Placeholder for future filters
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              onChanged: (val) {
                // Debounce or trigger search as needed
                // For wireframe, we perform live search
                _performSearch(val);
              },
              onSubmitted: (val) => _performSearch(val),
              decoration: InputDecoration(
                hintText: 'Search books, authors, subjects…',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
            const SizedBox(height: 12.0),
            // Optional quick filters row (wireframe)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Chip(label: Text('All')),
                Chip(label: Text('Titles')),
                Chip(label: Text('Authors')),
              ],
            ),
            const SizedBox(height: 8.0),
            // Results area
            _buildResults(),
          ],
        ),
      ),
    );
  }
}