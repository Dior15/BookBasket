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
      "lastReadOn": query.docs.first["lastReadOn"].toDate().toString().substring(0, 10),
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

}