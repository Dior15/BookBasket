part of "firebase_db.dart";

// A USER SHOULD ALWAYS BE FRIENDS WITH THEMSELVES TO ENSURE THAT THE FRIEND
//  FIELD EXISTS AND DOESN'T BREAK THE FRIEND LIST PAGE

// ENSURE ALL THE FIELDS ARE POPULATED SO THAT THE FRIEND PAGE DOESN'T BREAK
//  FROM TRYING TO RENDER MISSING FIELDS

extension Friends on FirebaseDB {
  /// Receive the dictionary with all of a user's friend information
  Future<Map<String, dynamic>> getFriendInfo(String username) async {
    QuerySnapshot<Map<String, dynamic>> query = await FirebaseDB._database
        .collection("friends")
        .where("username", isEqualTo: username)
        .limit(1)
        .get();

    return {
      "username": query.docs.first["username"],
      "lastReadBook": query.docs.first["lastReadBook"],
      "lastReadOn":
          query.docs.first["lastReadOn"].toDate().toString().substring(0, 10),
      "friends": query.docs.first["friends"]
    };
  }

  Stream<Map<String, dynamic>> getFriendInfoStream(String username) {
    return FirebaseDB._database
        .collection("friends")
        .where("username", isEqualTo: username)
        .limit(1)
        .snapshots()
        .map((querySnapshot) {
      if (querySnapshot.docs.isEmpty) return {};

      final doc = querySnapshot.docs.first;
      return {
        "username": doc["username"],
        "lastReadBook": doc["lastReadBook"],
        // Safely convert the Timestamp into a readable date string
        "lastReadOn": doc["lastReadOn"].toDate().toString().substring(0, 10),
        "friends": doc["friends"]
      };
    });
  }

  /// Updates the last book read and timestamp in the friends collection
  Future<void> updateLastReadBook(String username, String bookTitle) async {
    QuerySnapshot<Map<String, dynamic>> friendQuery = await FirebaseDB._database
        .collection("friends")
        .where("username", isEqualTo: username)
        .limit(1)
        .get();

    if (friendQuery.docs.isNotEmpty) {
      await FirebaseDB._database
          .collection("friends")
          .doc(friendQuery.docs.first.id)
          .update({
        "lastReadBook": bookTitle,
        // Automatically updates the timestamp to the exact moment they opened it
        "lastReadOn": Timestamp.fromDate(DateTime.now())
      });
    }
  }

  /// Adds [friendEmail] to [currentUserEmail]'s friends list.
  /// Returns `null` on success, or an error message string if something went wrong (e.g. user not found, already a friend, adding yourself).
  Future<String?> addFriend(String currentUserEmail, String friendEmail) async {
    if (friendEmail.trim().toLowerCase() ==
        currentUserEmail.trim().toLowerCase()) {
      return "You can't add yourself as a friend.";
    }

    // 1. Verify the target user exists in the friends collection
    QuerySnapshot<Map<String, dynamic>> friendQuery = await FirebaseDB._database
        .collection("friends")
        .where("username", isEqualTo: friendEmail.trim())
        .limit(1)
        .get();

    if (friendQuery.docs.isEmpty) {
      return "No user found with that email.";
    }

    // 2. Find the current user's document
    QuerySnapshot<Map<String, dynamic>> currentUserQuery = await FirebaseDB
        ._database
        .collection("friends")
        .where("username", isEqualTo: currentUserEmail.trim())
        .limit(1)
        .get();

    if (currentUserQuery.docs.isEmpty) {
      return "Could not find your account. Please try again.";
    }

    final currentUserDoc = currentUserQuery.docs.first;
    final List<dynamic> existingFriends = currentUserDoc["friends"] ?? [];

    if (existingFriends.contains(friendEmail.trim())) {
      return "You are already friends with this user.";
    }

    // 3. Add the friend using arrayUnion to avoid duplicates
    await FirebaseDB._database
        .collection("friends")
        .doc(currentUserDoc.id)
        .update({
      "friends": FieldValue.arrayUnion([friendEmail.trim()])
    });

    return null; // null = success
  }

  /// Removes [friendEmail] from [currentUserEmail]'s friends list.
  Future<void> removeFriend(String currentUserEmail, String friendEmail) async {
    QuerySnapshot<Map<String, dynamic>> currentUserQuery = await FirebaseDB
        ._database
        .collection("friends")
        .where("username", isEqualTo: currentUserEmail.trim())
        .limit(1)
        .get();

    if (currentUserQuery.docs.isEmpty) return;

    await FirebaseDB._database
        .collection("friends")
        .doc(currentUserQuery.docs.first.id)
        .update({
      "friends": FieldValue.arrayRemove([friendEmail.trim()])
    });
  }
}
