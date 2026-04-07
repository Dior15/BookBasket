part of "firebase_db.dart";

extension Users on FirebaseDB {
  /// Receive a list of all users in the database
  Future<List<Map<String, dynamic>>> getUsers() async {
    QuerySnapshot<Map<String, dynamic>> query = await FirebaseDB._database
        .collection("users")
        .orderBy("username")
        .get();

    return query.docs.map((document) {
      return document.data();
    }).toList();
  }

  /// Pass a username and password, receive a boolean indicating whether that username password pair is valid/exists
  Future<bool> validateLogin(String username, String password) async {
    QuerySnapshot<Map<String, dynamic>> query = await FirebaseDB._database
        .collection("users")
        .where("username", isEqualTo: username)
        .where("password", isEqualTo: password)
        .get();

    return query.docs.length == 1;
  }

  /// Checks if the passed user is an admin
  Future<bool> isAdmin(String username) async {
    QuerySnapshot<Map<String, dynamic>> query = await FirebaseDB._database
        .collection("users")
        .where("username", isEqualTo: username)
        .limit(1)
        .get();

    return query.docs.first["isAdmin"];
  }

  /// Changes the passed user to have the passed role
  Future<void> changeIsAdmin(String username, bool isAdmin) async {
    QuerySnapshot<Map<String, dynamic>> query = await FirebaseDB._database
        .collection("users")
        .where("username", isEqualTo: username)
        .limit(1)
        .get();

    if (query.docs.first.exists) {
      await FirebaseDB._database
          .collection("users")
          .doc(query.docs.first.id)
          .update({"isAdmin": isAdmin});
    }
  }

  /// Add a user from the passed information
  Future<void> addUser(String username, String password, bool isAdmin) async {
    final safeUsername = username.trim().toLowerCase();

    await FirebaseDB._database.collection("users").add({
      "username": safeUsername,
      "password": password,
      "isAdmin": isAdmin,
    });

    await FirebaseDB._database.collection("friends").add({
      "username": safeUsername,
      "lastReadBook": "Nothing Yet",
      "lastReadOn": Timestamp.fromDate(DateTime.now()),
      "friends": [safeUsername],
      "incomingRequests": <String>[],
      "outgoingRequests": <String>[],
    });
  }

  /// Deletes the user based on the passed username
  Future<void> deleteUser(String username) async {
    QuerySnapshot<Map<String, dynamic>> query = await FirebaseDB._database
        .collection("users")
        .where("username", isEqualTo: username)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      await FirebaseDB._database
          .collection("users")
          .doc(query.docs.first.id)
          .delete();
    }
  }

  /// Checks if a user already exists in the database
  Future<bool> doesUserExist(String email) async {
    QuerySnapshot<Map<String, dynamic>> query = await FirebaseDB._database
        .collection("users")
        .where("username", isEqualTo: email)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }
}