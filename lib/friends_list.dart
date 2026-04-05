import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'firebase_database/firebase_db.dart';

class FriendsListPage extends StatefulWidget {
  const FriendsListPage({super.key});

  @override
  State<StatefulWidget> createState() => FriendsListState();
}

class FriendsListState extends State<FriendsListPage> {

  late Future<List<Map<String, dynamic>>> _friendsFuture;

  @override
  void initState() {
    super.initState();
    // Assign the Future exactly once when the page loads
    _friendsFuture = FriendInfoManager.getFriendInfo();
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
            'See what your friends are reading and discover new books together.',
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
    return Column(
      children: [
        heroCard(),
        Expanded(
            child: FutureBuilder(
              future: _friendsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No friends found."));
                }

                List<Map<String, dynamic>> data = snapshot.data!;

                return ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final friend = data[index];
                    final String heroTagAvatar = 'avatar_${friend["username"]}_$index';
                    final String heroTagName = 'name_${friend["username"]}_$index';

                    return GestureDetector(
                      onTap: () {
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
                      child: Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
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
                                          friend["lastReadBook"],
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          friend["lastReadOn"],
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
                          )
                      ),
                    );
                  },
                );
              },
            )
        )
      ],
    );
  }
}

class FriendInfoManager {
  // We change this to return the Future directly instead of saving it to a static variable
  static Future<List<Map<String, dynamic>>> getFriendInfo() async {
    String? username = await AuthService.getEmail();
    if (username == null) return []; // Safety check

    Map<String, dynamic> currentUserFriendInfo = await FirebaseDB.getReference().getFriendInfo(username);

    // FIX 1: Safely handle if the "friends" field is null, missing, or empty
    List<dynamic> rawFriends = currentUserFriendInfo["friends"] ?? [];
    List<String> friendsList = rawFriends.whereType<String>().toList();

    if (friendsList.isEmpty) {
      return []; // Return an empty list instead of crashing
    }

    // Wait for all the friend data to fetch and return it
    return await Future.wait(friendsList.map((friend) async {
      return await FirebaseDB.getReference().getFriendInfo(friend);
    }).toList());
  }
}

// --- NEW: The Detail Page that the user expands into ---
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
                        friendData["lastReadBook"],
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
                            "Last active: ${friendData["lastReadOn"]}",
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