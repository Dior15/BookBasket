import 'dart:async';

import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'firebase_database/firebase_db.dart';

class FriendsListPage extends StatefulWidget {
  const FriendsListPage({super.key});

  @override
  State<FriendsListPage> createState() => _FriendsListPageState();
}

class _FriendsListPageState extends State<FriendsListPage> {
  final FirebaseDB _db = FirebaseDB.getReference();

  String? _currentUsername;
  bool _isLoading = true;

  Map<String, dynamic> _currentUserData = {};
  final Map<String, Map<String, dynamic>> _profiles = {};

  StreamSubscription? _currentUserSub;
  final List<StreamSubscription> _profileSubs = [];

  String? _selectedFriendForRemoval;

  @override
  void initState() {
    super.initState();
    _listenToFriendsPage();
  }

  @override
  void dispose() {
    _currentUserSub?.cancel();
    for (final sub in _profileSubs) {
      sub.cancel();
    }
    super.dispose();
  }

  Future<void> _listenToFriendsPage() async {
    final username = await AuthService.getEmail();
    if (username == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      return;
    }

    _currentUsername = username.trim().toLowerCase();

    _currentUserSub = _db
        .getFriendInfoStream(_currentUsername!)
        .listen((currentUserData) {
      if (!mounted) return;

      final friends = List<String>.from(currentUserData['friends'] ?? const [])
        ..remove(_currentUsername);
      final incoming = List<String>.from(
        currentUserData['incomingRequests'] ?? const [],
      );
      final outgoing = List<String>.from(
        currentUserData['outgoingRequests'] ?? const [],
      );

      final usernamesToWatch = <String>{...friends, ...incoming, ...outgoing};

      for (final sub in _profileSubs) {
        sub.cancel();
      }
      _profileSubs.clear();
      _profiles.clear();

      if (usernamesToWatch.isEmpty) {
        setState(() {
          _currentUserData = currentUserData;
          _isLoading = false;
        });
        return;
      }

      for (final otherUsername in usernamesToWatch) {
        final sub = _db.getFriendInfoStream(otherUsername).listen((profileData) {
          if (!mounted) return;
          setState(() {
            _currentUserData = currentUserData;
            if (profileData.isNotEmpty) {
              _profiles[otherUsername] = profileData;
            }
            _isLoading = false;
          });
        });
        _profileSubs.add(sub);
      }

      setState(() {
        _currentUserData = currentUserData;
        _isLoading = false;
      });
    });
  }

  List<Map<String, dynamic>> _profilesFor(List<String> usernames) {
    return usernames
        .where((username) => username != _currentUsername)
        .map((username) => _profiles[username])
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<void> _showSendRequestDialog() async {
    final controller = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF3949AB)),
                  SizedBox(width: 10),
                  Text('Send Friend Request'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter the other user\'s email to send them a friend request.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email address',
                      hintText: 'friend@example.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                    final current = _currentUsername;
                    if (current == null) return;

                    setDialogState(() {
                      isSubmitting = true;
                    });

                    final error = await _db.sendFriendRequest(
                      current,
                      controller.text,
                    );

                    if (!mounted) return;
                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          error ?? 'Friend request sent successfully.',
                        ),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF3949AB),
                  ),
                  child: const Text('Send'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _acceptRequest(String requesterEmail) async {
    if (_currentUsername == null) return;

    final error = await _db.acceptFriendRequest(_currentUsername!, requesterEmail);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Friend request accepted.'),
      ),
    );
  }

  Future<void> _denyRequest(String requesterEmail) async {
    if (_currentUsername == null) return;

    await _db.denyFriendRequest(_currentUsername!, requesterEmail);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Friend request denied.')),
    );
  }

  Future<void> _cancelRequest(String targetEmail) async {
    if (_currentUsername == null) return;

    await _db.cancelFriendRequest(_currentUsername!, targetEmail);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Friend request cancelled.')),
    );
  }

  Future<void> _removeFriend(String friendEmail) async {
    if (_currentUsername == null) return;

    await _db.removeFriend(_currentUsername!, friendEmail);
    if (!mounted) return;

    setState(() {
      _selectedFriendForRemoval = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Friend removed.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final incoming = _profilesFor(
      List<String>.from(_currentUserData['incomingRequests'] ?? const []),
    );
    final outgoing = _profilesFor(
      List<String>.from(_currentUserData['outgoingRequests'] ?? const []),
    );
    final friends = _profilesFor(
      List<String>.from(_currentUserData['friends'] ?? const []),
    );

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FriendsHeader(
              totalFriends: friends.length,
              incomingCount: incoming.length,
              outgoingCount: outgoing.length,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  _buildRequestSection(
                    title: 'Incoming Requests',
                    subtitle: 'Accept or deny people who want to add you.',
                    icon: Icons.mark_email_unread_rounded,
                    items: incoming,
                    emptyText: 'No incoming requests right now.',
                    itemBuilder: (request) => _RequestCard(
                      email: request['username'] ?? '',
                      book: request['lastReadBook'] ?? 'Nothing Yet',
                      lastReadOn: request['lastReadOn'] ?? '',
                      primaryLabel: 'Accept',
                      secondaryLabel: 'Deny',
                      onPrimaryPressed: () => _acceptRequest(
                        request['username'] ?? '',
                      ),
                      onSecondaryPressed: () => _denyRequest(
                        request['username'] ?? '',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRequestSection(
                    title: 'Sent Requests',
                    subtitle: 'These users still need to respond.',
                    icon: Icons.send_rounded,
                    items: outgoing,
                    emptyText: 'No pending sent requests.',
                    itemBuilder: (request) => _RequestCard(
                      email: request['username'] ?? '',
                      book: request['lastReadBook'] ?? 'Nothing Yet',
                      lastReadOn: request['lastReadOn'] ?? '',
                      primaryLabel: 'Cancel',
                      secondaryLabel: null,
                      onPrimaryPressed: () => _cancelRequest(
                        request['username'] ?? '',
                      ),
                      onSecondaryPressed: null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFriendsSection(friends),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 24,
          child: FloatingActionButton.extended(
            onPressed: _showSendRequestDialog,
            backgroundColor: const Color(0xFF3949AB),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Add Friend'),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Map<String, dynamic>> items,
    required String emptyText,
    required Widget Function(Map<String, dynamic>) itemBuilder,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF3949AB)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Text(
              emptyText,
              style: const TextStyle(color: Colors.grey),
            )
          else
            ...items.map(itemBuilder),
        ],
      ),
    );
  }

  Widget _buildFriendsSection(List<Map<String, dynamic>> friends) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.people_alt_rounded, color: Color(0xFF3949AB)),
              SizedBox(width: 10),
              Text(
                'Your Friends',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Long-press a friend card if you want to remove them.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          if (friends.isEmpty)
            const Text(
              'You do not have any friends added yet.',
              style: TextStyle(color: Colors.grey),
            )
          else
            ...friends.map((friend) {
              final email = friend['username'] ?? '';
              final isSelected = _selectedFriendForRemoval == email;

              return GestureDetector(
                onLongPress: () {
                  setState(() {
                    _selectedFriendForRemoval = email;
                  });
                },
                onTap: () {
                  if (_selectedFriendForRemoval != null) {
                    setState(() {
                      _selectedFriendForRemoval = null;
                    });
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FriendDetailPage(friendData: friend),
                    ),
                  );
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.red.withOpacity(0.06)
                            : Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected
                            ? Border.all(
                          color: Colors.redAccent.withOpacity(0.4),
                          width: 1.5,
                        )
                            : null,
                      ),
                      child: Row(
                        children: [
                          _AvatarLetter(email: email, radius: 24),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  email,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  friend['lastReadBook'] ?? 'Nothing Yet',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  friend['lastReadOn'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        top: -6,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => _removeFriend(email),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _FriendsHeader extends StatelessWidget {
  final int totalFriends;
  final int incomingCount;
  final int outgoingCount;

  const _FriendsHeader({
    required this.totalFriends,
    required this.incomingCount,
    required this.outgoingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF5C6BC0), Color(0xFF3949AB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Friends',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Send requests, manage pending invites, and keep track of your reading friends.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeaderStat(label: 'Friends', value: '$totalFriends'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeaderStat(label: 'Incoming', value: '$incomingCount'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeaderStat(label: 'Sent', value: '$outgoingCount'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeaderStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final String email;
  final String book;
  final String lastReadOn;
  final String primaryLabel;
  final String? secondaryLabel;
  final VoidCallback onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;

  const _RequestCard({
    required this.email,
    required this.book,
    required this.lastReadOn,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimaryPressed,
    required this.onSecondaryPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _AvatarLetter(email: email, radius: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      email,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    if (lastReadOn.isNotEmpty)
                      Text(
                        lastReadOn,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
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
                child: FilledButton(
                  onPressed: onPrimaryPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF3949AB),
                  ),
                  child: Text(primaryLabel),
                ),
              ),
              if (secondaryLabel != null && onSecondaryPressed != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSecondaryPressed,
                    child: Text(secondaryLabel!),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AvatarLetter extends StatelessWidget {
  final String email;
  final double radius;

  const _AvatarLetter({required this.email, required this.radius});

  @override
  Widget build(BuildContext context) {
    final letter = email.isEmpty ? '?' : email.substring(0, 1).toUpperCase();

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF3949AB),
      child: Text(
        letter,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.75,
        ),
      ),
    );
  }
}

class FriendDetailPage extends StatelessWidget {
  final Map<String, dynamic> friendData;

  const FriendDetailPage({super.key, required this.friendData});

  @override
  Widget build(BuildContext context) {
    final email = friendData['username'] ?? '';
    final book = friendData['lastReadBook'] ?? 'Nothing Yet';
    final lastReadOn = friendData['lastReadOn'] ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 18),
              _AvatarLetter(email: email, radius: 46),
              const SizedBox(height: 18),
              Text(
                email,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reading Activity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(label: 'Last read book', value: book),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: 'Last updated',
                      value: lastReadOn.isEmpty ? 'No date yet' : lastReadOn,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}