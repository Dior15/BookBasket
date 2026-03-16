class FriendModel {
  final String id;
  final String name;
  final String avatarLetter;
  final String currentBook;
  final String status;
  final int readingStreak;
  final int mutualBooks;
  final int compatibility;
  final bool incomingRequest;
  final bool isFavorite;
  final bool hasUnreadMessage;
  final String recentActivity;
  final String lastInteraction;

  const FriendModel({
    required this.id,
    required this.name,
    required this.avatarLetter,
    required this.currentBook,
    required this.status,
    required this.readingStreak,
    required this.mutualBooks,
    required this.compatibility,
    required this.incomingRequest,
    required this.isFavorite,
    required this.hasUnreadMessage,
    required this.recentActivity,
    required this.lastInteraction,
  });

  FriendModel copyWith({
    String? id,
    String? name,
    String? avatarLetter,
    String? currentBook,
    String? status,
    int? readingStreak,
    int? mutualBooks,
    int? compatibility,
    bool? incomingRequest,
    bool? isFavorite,
    bool? hasUnreadMessage,
    String? recentActivity,
    String? lastInteraction,
  }) {
    return FriendModel(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarLetter: avatarLetter ?? this.avatarLetter,
      currentBook: currentBook ?? this.currentBook,
      status: status ?? this.status,
      readingStreak: readingStreak ?? this.readingStreak,
      mutualBooks: mutualBooks ?? this.mutualBooks,
      compatibility: compatibility ?? this.compatibility,
      incomingRequest: incomingRequest ?? this.incomingRequest,
      isFavorite: isFavorite ?? this.isFavorite,
      hasUnreadMessage: hasUnreadMessage ?? this.hasUnreadMessage,
      recentActivity: recentActivity ?? this.recentActivity,
      lastInteraction: lastInteraction ?? this.lastInteraction,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarLetter': avatarLetter,
      'currentBook': currentBook,
      'status': status,
      'readingStreak': readingStreak,
      'mutualBooks': mutualBooks,
      'compatibility': compatibility,
      'incomingRequest': incomingRequest,
      'isFavorite': isFavorite,
      'hasUnreadMessage': hasUnreadMessage,
      'recentActivity': recentActivity,
      'lastInteraction': lastInteraction,
    };
  }

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarLetter: json['avatarLetter'] as String,
      currentBook: json['currentBook'] as String,
      status: json['status'] as String,
      readingStreak: json['readingStreak'] as int,
      mutualBooks: json['mutualBooks'] as int,
      compatibility: json['compatibility'] as int,
      incomingRequest: json['incomingRequest'] as bool,
      isFavorite: json['isFavorite'] as bool,
      hasUnreadMessage: json['hasUnreadMessage'] as bool,
      recentActivity: json['recentActivity'] as String,
      lastInteraction: json['lastInteraction'] as String,
    );
  }
}