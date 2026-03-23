part of "firebase_db.dart";

extension Users on FirebaseDB {
  /// Receive a list of all users in the database
  Future<List<Map<String, dynamic>>> getUsers() async {
    QuerySnapshot<Map<String, dynamic>> query = await FirebaseDB._database
      .collection("users")
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

  Future<bool> isAdmin(String username) async {
    QuerySnapshot<Map<String, dynamic>> query = await FirebaseDB._database
      .collection("users")
      .where("username", isEqualTo: username)
      .get();

    return(query.docs.first["isAdmin"]);
  }
}