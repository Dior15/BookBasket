import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'friend_model.dart';

class FriendsStorage {
  static const String _friendsKey = 'bookbasket_friends_v1';

  static Future<List<FriendModel>> loadFriends() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_friendsKey);

    if (raw == null || raw.isEmpty) {
      final defaults = _defaultFriends();
      await saveFriends(defaults);
      return defaults;
    }

    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => FriendModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<void> saveFriends(List<FriendModel> friends) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      friends.map((friend) => friend.toJson()).toList(),
    );
    await prefs.setString(_friendsKey, encoded);
  }

  static List<FriendModel> _defaultFriends() {
    return const [
      FriendModel(
        id: 'friend_1',
        name: 'Alex Chen',
        avatarLetter: 'A',
        currentBook: 'Atomic Habits',
        status: 'Reading tonight',
        readingStreak: 11,
        mutualBooks: 4,
        compatibility: 92,
        incomingRequest: false,
        isFavorite: true,
        hasUnreadMessage: true,
        recentActivity: 'Finished 2 chapters this week',
        lastInteraction: '2h ago',
      ),
      FriendModel(
        id: 'friend_2',
        name: 'Sarah Kim',
        avatarLetter: 'S',
        currentBook: 'Clean Code',
        status: 'Open to recommendations',
        readingStreak: 7,
        mutualBooks: 3,
        compatibility: 88,
        incomingRequest: false,
        isFavorite: false,
        hasUnreadMessage: false,
        recentActivity: 'Shared a new quote',
        lastInteraction: 'Yesterday',
      ),
      FriendModel(
        id: 'friend_3',
        name: 'David Lee',
        avatarLetter: 'D',
        currentBook: 'Flutter in Action',
        status: 'Looking for a reading buddy',
        readingStreak: 18,
        mutualBooks: 6,
        compatibility: 96,
        incomingRequest: false,
        isFavorite: true,
        hasUnreadMessage: false,
        recentActivity: 'Started a coding readathon',
        lastInteraction: 'Today',
      ),
      FriendModel(
        id: 'friend_4',
        name: 'Maria Garcia',
        avatarLetter: 'M',
        currentBook: 'The Pragmatic Programmer',
        status: 'On chapter 8',
        readingStreak: 5,
        mutualBooks: 2,
        compatibility: 81,
        incomingRequest: false,
        isFavorite: false,
        hasUnreadMessage: true,
        recentActivity: 'Rated a book 5 stars',
        lastInteraction: '3d ago',
      ),
      FriendModel(
        id: 'request_1',
        name: 'Nina Patel',
        avatarLetter: 'N',
        currentBook: 'It Ends With Us',
        status: 'Sent you a friend request',
        readingStreak: 9,
        mutualBooks: 2,
        compatibility: 84,
        incomingRequest: true,
        isFavorite: false,
        hasUnreadMessage: false,
        recentActivity: 'Enjoys romance and drama reads',
        lastInteraction: 'New',
      ),
    ];
  }
}