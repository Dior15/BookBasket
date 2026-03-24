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

    return(query.docs.length == 1);
  }

  /// Checks if the passed user is an admin
  Future<bool> isAdmin(String username) async {
    QuerySnapshot<Map<String, dynamic>> query = await FirebaseDB._database
      .collection("users")
      .where("username", isEqualTo: username)
      .limit(1)
      .get();

    return(query.docs.first["isAdmin"]);
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
    await FirebaseDB._database
        .collection("users")
        .add({"username": username, "password": password, "isAdmin": isAdmin});
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
}