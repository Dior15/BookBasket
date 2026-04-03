import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'firebase_database/firebase_db.dart';

class FriendsListPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => FriendsListState();
}

class FriendsListState extends State<FriendsListPage> {
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
        ],
      ),
    );
  }

  @override
  @override
  void initState() {
    super.initState();
    FriendInfoManager.getFriendInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        heroCard(),
        Expanded(
          child:
            RefreshIndicator(
              onRefresh: () async {
                await FriendInfoManager.getFriendInfo();
                setState(() {});
              },
              child: FutureBuilder(
                future: FriendInfoManager.friendData,
                builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                  List<Map<String, dynamic>> data = [];

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    data = [];
                  } else if (snapshot.hasData) {
                    data = snapshot.data;
                  }

                  return ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(16, 3, 16, 3),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: Colors.white.withValues(),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1A237E).withOpacity(0.28),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child:
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24, // size
                              backgroundColor: Colors.indigo,
                              child: Text(
                                data[index]["username"].toString().substring(0, 1).toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data[index]["username"],
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                                Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Last Read: ",
                                          style: TextStyle(
                                              fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          "Read On: ",
                                          style: TextStyle(
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            data[index]["lastReadBook"],
                                          style: TextStyle(
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          data[index]["lastReadOn"],
                                          style: TextStyle(
                                            fontSize: 14,
                                          ),
                                        )
                                      ],
                                    )
                                  ],
                                )
                              ]
                            )
                          ],
                        )
                      );
                    }
                  );
                },
              )
            )
        )
      ]
    );
  }
}

class FriendInfoManager {
  static Future<List<Map<String, dynamic>>> friendData = Future.value([]);

  static Future<void> getFriendInfo() async {
    String? username = await AuthService.getEmail();
    Map<String, dynamic> currentUserFriendInfo = await FirebaseDB.getReference().getFriendInfo(username!);

    friendData = Future.wait(List<String>.from(currentUserFriendInfo["friends"]).map((friend) async {
      return await FirebaseDB.getReference().getFriendInfo(friend);
    }).toList());
  }
}