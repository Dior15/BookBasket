import 'dart:async';
import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'firebase_database/firebase_db.dart';

class FriendsListPage extends StatefulWidget {
  const FriendsListPage({super.key});

  @override
  State<StatefulWidget> createState() => FriendsListState();
}

class FriendsListState extends State<FriendsListPage> {
  // We hold the live list of friend data here
  List<Map<String, dynamic>> _friendsData = [];
  bool _isLoading = true;
  String? _currentUsername;
  // Tracks which friend card is showing the remove X
  String? _selectedFriendForRemoval;

  StreamSubscription? _currentUserSub;
  List<StreamSubscription> _friendSubs = [];

  @override
  void initState() {
    super.initState();
    _listenToFriends();
  }

  @override
  void dispose() {
    // Always clean up streams when leaving the page!
    _currentUserSub?.cancel();
    for (var sub in _friendSubs) {
      sub.cancel();
    }
    super.dispose();
  }

  Future<void> _listenToFriends() async {
    String? currentUsername = await AuthService.getEmail();
    if (currentUsername == null) return;
    _currentUsername = currentUsername;

    // 1. Listen to the current user's document to get their friend list
    _currentUserSub = FirebaseDB.getReference()
        .getFriendInfoStream(currentUsername)
        .listen((currentUserData) {

      if (!mounted) return;

      List<dynamic> rawFriends = currentUserData["friends"] ?? [];
      List<String> friendUsernames = rawFriends.whereType<String>().toList();

      if (friendUsernames.isEmpty) {
        setState(() {
          _friendsData = [];
          _isLoading = false;
        });
        return;
      }

      // 2. Clear old subscriptions and set up new ones for each friend
      for (var sub in _friendSubs) {
        sub.cancel();
      }
      _friendSubs.clear();

      // We use a temporary map to keep the friends in order while they load
      Map<String, Map<String, dynamic>> incomingData = {};

      for (String friendName in friendUsernames) {
        var sub = FirebaseDB.getReference()
            .getFriendInfoStream(friendName)
            .listen((friendData) {

          if (!mounted) return;

          // When a friend updates their book, this block fires automatically!
          setState(() {
            incomingData[friendName] = friendData;
            _friendsData = incomingData.values.toList();
            _isLoading = false;
          });
        });

        _friendSubs.add(sub);
      }
    });
  }

  Future<void> _showAddFriendDialog() async {
    final TextEditingController emailController = TextEditingController();
    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.person_add_rounded, color: Color(0xFF3949AB), size: 26),
                  SizedBox(width: 10),
                  Text(
                    'Add Friend',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Enter your friend's email",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Email address',
                      hintText: 'friend@example.com',
                      prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF3949AB)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF3949AB), width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF3949AB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          final email = emailController.text.trim();
                          if (email.isEmpty) return;

                          setDialogState(() => isLoading = true);

                          final error = await FirebaseDB.getReference()
                              .addFriend(_currentUsername!, email);

                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);

                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                error ?? 'Friend added successfully! 🎉',
                              ),
                              backgroundColor: error != null
                                  ? Colors.redAccent
                                  : const Color(0xFF3949AB),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Add Friend'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget heroCard() {
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups_rounded, color: Colors.white, size: 26),
              SizedBox(width: 10),
              Text(
                'Reading Friends',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'See what your friends are reading and discover new books together. \nPress and hold to remove a friend.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            heroCard(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _friendsData.isEmpty
                      ? const Center(child: Text("No friends found."))
                      : ListView.builder(
                          itemCount: _friendsData.length,
                          itemBuilder: (context, index) {
                            final friend = _friendsData[index];
                            final String heroTagAvatar = 'avatar_${friend["username"]}_$index';
                            final String heroTagName = 'name_${friend["username"]}_$index';
                            final bool isSelected =
                                _selectedFriendForRemoval == friend["username"];

                            return GestureDetector(
                              onTap: () {
                                if (_selectedFriendForRemoval != null) {
                                  // Tap anywhere to dismiss the X
                                  setState(() => _selectedFriendForRemoval = null);
                                  return;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FriendDetailPage(
                                      friendData: friend,
                                      avatarTag: heroTagAvatar,
                                      nameTag: heroTagName,
                                    ),
                                  ),
                                );
                              },
                              onLongPress: () {
                                setState(() {
                                  _selectedFriendForRemoval = friend["username"];
                                });
                              },
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.red.withOpacity(0.06)
                                          : Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(16),
                                      border: isSelected
                                          ? Border.all(color: Colors.redAccent.withOpacity(0.4), width: 1.5)
                                          : null,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Hero(
                                          tag: heroTagAvatar,
                                          child: CircleAvatar(
                                            radius: 25,
                                            backgroundColor: const Color(0xFF3949AB),
                                            child: Text(
                                              friend["username"].toString().substring(0, 1).toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Hero(
                                                tag: heroTagName,
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: Text(
                                                    friend["username"],
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    friend["lastReadBook"] ?? "Nothing yet",
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    friend["lastReadOn"] ?? "",
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                  )
                                                ],
                                              )
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),

                                  // X remove button — top right corner
                                  if (isSelected)
                                    Positioned(
                                      top: -6,
                                      right: 10,
                                      child: GestureDetector(
                                        onTap: () async {
                                          setState(() => _selectedFriendForRemoval = null);
                                          await FirebaseDB.getReference().removeFriend(
                                            _currentUsername!,
                                            friend["username"],
                                          );
                                        },
                                        child: Container(
                                          width: 26,
                                          height: 26,
                                          decoration: const BoxDecoration(
                                            color: Colors.redAccent,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              )
                                            ],
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
                          },
                        ),
            ),
          ],
        ),

        // Floating Action Button — bottom right
        if (_currentUsername != null)
          Positioned(
            bottom: 24,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: _showAddFriendDialog,
              backgroundColor: const Color(0xFF3949AB),
              foregroundColor: Colors.white,
              elevation: 6,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text(
                'Add Friend',
                style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.3),
              ),
            ),
          ),
      ],
    );
  }
}

// The Detail Page that the user expands into
class FriendDetailPage extends StatelessWidget {
  final Map<String, dynamic> friendData;
  final String avatarTag;
  final String nameTag;

  const FriendDetailPage({
    super.key,
    required this.friendData,
    required this.avatarTag,
    required this.nameTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Hero(
                tag: avatarTag,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: const Color(0xFF3949AB),
                  child: Text(
                    friendData["username"].toString().substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Hero(
                tag: nameTag,
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    friendData["username"],
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Extra Details Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.menu_book_rounded, size: 40, color: Color(0xFF3949AB)),
                      const SizedBox(height: 16),
                      const Text(
                        "Currently Reading",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        friendData["lastReadBook"] ?? "Nothing yet",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.access_time_rounded, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            "Last active: ${friendData["lastReadOn"] ?? ""}",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}