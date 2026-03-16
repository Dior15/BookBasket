import 'dart:math';

import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'database/db.dart';
import 'friends/friend_model.dart';
import 'friends/friends_storage.dart';

enum FriendFilter { all, favorites, requests }

class FriendsListPage extends StatefulWidget {
  const FriendsListPage({super.key});

  @override
  State<FriendsListPage> createState() => _FriendsListPageState();
}

class _FriendsListPageState extends State<FriendsListPage> {
  final TextEditingController _searchController = TextEditingController();

  List<FriendModel> _friends = [];
  List<String> _bookTitles = [];
  FriendFilter _filter = FriendFilter.all;
  bool _loading = true;
  String _currentUser = 'Reader';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final loadedFriends = await FriendsStorage.loadFriends();
    final email = await AuthService.getEmail();

    try {
      final db = await DB.getReference();
      final books = await db.getBooks();
      _bookTitles = books
          .map((book) => book['title']?.toString() ?? '')
          .where((title) => title.isNotEmpty)
          .toList();
    } catch (_) {
      _bookTitles = const [
        'Camp X',
        'The Gunslinger',
        'It Ends With Us',
        'Twelve Angry Men',
        'Under The Dome',
        'Sisters',
      ];
    }

    if (!mounted) return;
    setState(() {
      _friends = loadedFriends;
      _currentUser = email ?? 'Reader';
      _loading = false;
    });
  }

  Future<void> _persistFriends() async {
    await FriendsStorage.saveFriends(_friends);
  }

  List<FriendModel> get _visibleFriends {
    final query = _searchController.text.trim().toLowerCase();

    return _friends.where((friend) {
      final matchesFilter = switch (_filter) {
        FriendFilter.all => !friend.incomingRequest,
        FriendFilter.favorites => !friend.incomingRequest && friend.isFavorite,
        FriendFilter.requests => friend.incomingRequest,
      };

      final matchesQuery = query.isEmpty ||
          friend.name.toLowerCase().contains(query) ||
          friend.currentBook.toLowerCase().contains(query) ||
          friend.status.toLowerCase().contains(query);

      return matchesFilter && matchesQuery;
    }).toList();
  }

  int get _friendCount =>
      _friends.where((friend) => !friend.incomingRequest).length;

  int get _favoriteCount => _friends
      .where((friend) => !friend.incomingRequest && friend.isFavorite)
      .length;

  int get _requestCount =>
      _friends.where((friend) => friend.incomingRequest).length;

  Future<void> _toggleFavorite(FriendModel friend) async {
    setState(() {
      _friends = _friends.map((item) {
        if (item.id != friend.id) return item;
        return item.copyWith(isFavorite: !item.isFavorite);
      }).toList();
    });
    await _persistFriends();
  }

  Future<void> _sendWave(FriendModel friend) async {
    setState(() {
      _friends = _friends.map((item) {
        if (item.id != friend.id) return item;
        return item.copyWith(
          hasUnreadMessage: false,
          recentActivity: 'You sent a wave 👋',
          lastInteraction: 'Just now',
        );
      }).toList();
    });
    await _persistFriends();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Wave sent to ${friend.name}.')),
    );
  }

  Future<void> _acceptRequest(FriendModel friend) async {
    setState(() {
      _friends = _friends.map((item) {
        if (item.id != friend.id) return item;
        return item.copyWith(
          incomingRequest: false,
          recentActivity: 'You accepted the friend request',
          lastInteraction: 'Just now',
        );
      }).toList();
      _filter = FriendFilter.all;
    });
    await _persistFriends();
  }

  Future<void> _declineRequest(FriendModel friend) async {
    setState(() {
      _friends.removeWhere((item) => item.id == friend.id);
    });
    await _persistFriends();
  }

  Future<void> _removeFriend(FriendModel friend) async {
    setState(() {
      _friends.removeWhere((item) => item.id == friend.id);
    });
    await _persistFriends();
  }

  Future<void> _recommendBook(FriendModel friend) async {
    if (_bookTitles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No books found to recommend yet.')),
      );
      return;
    }

    String selectedBook = _bookTitles.first;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Recommend a book to ${friend.name}'),
          content: DropdownButtonFormField<String>(
            value: selectedBook,
            decoration: const InputDecoration(
              labelText: 'Choose a book',
              border: OutlineInputBorder(),
            ),
            items: _bookTitles
                .map(
                  (book) => DropdownMenuItem<String>(
                value: book,
                child: Text(book),
              ),
            )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                selectedBook = value;
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _applyRecommendation(friend, selectedBook);
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _applyRecommendation(FriendModel friend, String book) async {
    setState(() {
      _friends = _friends.map((item) {
        if (item.id != friend.id) return item;
        return item.copyWith(
          recentActivity: 'You recommended "$book"',
          lastInteraction: 'Just now',
          hasUnreadMessage: true,
        );
      }).toList();
    });
    await _persistFriends();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Recommendation sent: $book')),
    );
  }

  Future<void> _showAddFriendDialog() async {
    final nameController = TextEditingController();
    String selectedBook = _bookTitles.isNotEmpty ? _bookTitles.first : 'Camp X';
    String selectedStatus = 'Just joined BookBasket';

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add a friend'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Friend name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedBook,
                  decoration: const InputDecoration(
                    labelText: 'Current book',
                    border: OutlineInputBorder(),
                  ),
                  items: (_bookTitles.isEmpty
                      ? ['Camp X', 'Sisters']
                      : _bookTitles)
                      .map(
                        (book) => DropdownMenuItem<String>(
                      value: book,
                      child: Text(book),
                    ),
                  )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      selectedBook = value;
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Reading status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Just joined BookBasket',
                      child: Text('Just joined BookBasket'),
                    ),
                    DropdownMenuItem(
                      value: 'Reading tonight',
                      child: Text('Reading tonight'),
                    ),
                    DropdownMenuItem(
                      value: 'Looking for recommendations',
                      child: Text('Looking for recommendations'),
                    ),
                    DropdownMenuItem(
                      value: 'Open to buddy reads',
                      child: Text('Open to buddy reads'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      selectedStatus = value;
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final letter = name.substring(0, 1).toUpperCase();
                final random = Random();

                final newFriend = FriendModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  avatarLetter: letter,
                  currentBook: selectedBook,
                  status: selectedStatus,
                  readingStreak: 1 + random.nextInt(12),
                  mutualBooks: 1 + random.nextInt(5),
                  compatibility: 72 + random.nextInt(25),
                  incomingRequest: false,
                  isFavorite: false,
                  hasUnreadMessage: false,
                  recentActivity: 'You became friends on BookBasket',
                  lastInteraction: 'Just now',
                );

                setState(() {
                  _friends.insert(0, newFriend);
                });
                await _persistFriends();

                if (!mounted) return;
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
  }

  void _showFriendDetails(FriendModel friend) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF3949AB),
                    child: Text(
                      friend.avatarLetter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          friend.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(friend.status),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _toggleFavorite(friend),
                    icon: Icon(
                      friend.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: friend.isFavorite ? Colors.pink : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _detailChip(
                    Icons.menu_book_rounded,
                    'Reading ${friend.currentBook}',
                  ),
                  _detailChip(
                    Icons.local_fire_department_rounded,
                    '${friend.readingStreak} day streak',
                  ),
                  _detailChip(
                    Icons.auto_awesome_rounded,
                    '${friend.compatibility}% match',
                  ),
                  _detailChip(
                    Icons.collections_bookmark_rounded,
                    '${friend.mutualBooks} shared books',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Recent activity',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(friend.recentActivity),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _sendWave(friend);
                      },
                      icon: const Icon(Icons.waving_hand_rounded),
                      label: const Text('Wave'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _recommendBook(friend);
                      },
                      icon: const Icon(Icons.recommend_rounded),
                      label: const Text('Recommend'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF3949AB).withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF3949AB)),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.groups_rounded, color: Colors.white, size: 26),
              SizedBox(width: 10),
              Text(
                'Reading Friends',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'See what your friends are reading, share recommendations, and keep your reading circle active.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  color: Colors.white70,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Logged in as $_currentUser',
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _statCard(
              'Friends',
              _friendCount.toString(),
              Icons.group_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statCard(
              'Favorites',
              _favoriteCount.toString(),
              Icons.favorite_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statCard(
              'Requests',
              _requestCount.toString(),
              Icons.person_add_alt_1_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF3949AB)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _searchAndFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search friends or books',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                onPressed: _searchController.clear,
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All Friends'),
                selected: _filter == FriendFilter.all,
                onSelected: (_) => setState(() => _filter = FriendFilter.all),
              ),
              ChoiceChip(
                label: const Text('Favorites'),
                selected: _filter == FriendFilter.favorites,
                onSelected: (_) =>
                    setState(() => _filter = FriendFilter.favorites),
              ),
              ChoiceChip(
                label: Text('Requests ($_requestCount)'),
                selected: _filter == FriendFilter.requests,
                onSelected: (_) =>
                    setState(() => _filter = FriendFilter.requests),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _requestCard(FriendModel friend) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF3949AB),
                  child: Text(
                    friend.avatarLetter,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${friend.compatibility}% match • ${friend.currentBook}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _declineRequest(friend),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _acceptRequest(friend),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _friendCard(FriendModel friend) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showFriendDetails(friend),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF3949AB),
                        child: Text(
                          friend.avatarLetter,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (friend.hasUnreadMessage)
                        Positioned(
                          right: -1,
                          top: -1,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                friend.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (friend.isFavorite)
                              const Icon(
                                Icons.favorite,
                                color: Colors.pink,
                                size: 18,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(friend.status),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.menu_book_rounded, size: 16),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                'Reading: ${friend.currentBook}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'favorite':
                          _toggleFavorite(friend);
                          break;
                        case 'wave':
                          _sendWave(friend);
                          break;
                        case 'recommend':
                          _recommendBook(friend);
                          break;
                        case 'remove':
                          _removeFriend(friend);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'favorite',
                        child: Text(
                          friend.isFavorite
                              ? 'Remove favorite'
                              : 'Mark favorite',
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'wave',
                        child: Text('Send wave'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'recommend',
                        child: Text('Recommend book'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'remove',
                        child: Text('Remove friend'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _miniInfo(
                      Icons.auto_awesome_rounded,
                      '${friend.compatibility}% match',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _miniInfo(
                      Icons.local_fire_department_rounded,
                      '${friend.readingStreak} day streak',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _miniInfo(
                      Icons.collections_bookmark_rounded,
                      '${friend.mutualBooks} shared',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${friend.recentActivity} • ${friend.lastInteraction}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniInfo(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF3949AB)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final visibleFriends = _visibleFriends;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.only(bottom: 90),
          children: [
            _heroCard(),
            _statsRow(),
            _searchAndFilterBar(),
            if (visibleFriends.isEmpty)
              const Padding(
                padding: EdgeInsets.all(28),
                child: Center(
                  child: Text('No friends match this filter yet.'),
                ),
              )
            else
              ...visibleFriends.map(
                    (friend) => friend.incomingRequest
                    ? _requestCard(friend)
                    : _friendCard(friend),
              ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: _showAddFriendDialog,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Add Friend'),
          ),
        ),
      ],
    );
  }
}