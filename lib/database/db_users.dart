part of 'db.dart';

extension Users on DB {
  Future<List<Map<String, Object?>>> getUsers() async {
    return await DB._database.query(
      "users"
    );
  }

  Future<bool> validateLogin(String username, String password) async {
    List<Map<String, Object?>> user = await DB._database.query(
        "users",
        where: "username = ?",
        whereArgs: [username]
    );
    if (user.isNotEmpty && user.first["password"].toString() == password.toString()) {
      return(true);
    } else {
      return(false);
    }
  }

  /// Checks if the passed user is an admin
  Future<bool> isAdmin(String username) async {
    List<Map<String, Object?>> user = await DB._database.query(
        "users",
        where: "username = ?",
        whereArgs: [username]
    );
    return(user.isNotEmpty && user.first["isAdmin"] == 1); // REMEMBER THAT SQFLITE STORES BOOLEANS AS 0 OR 1
  }

  /// Changes the passed user to have the passed role
  Future<void> changeIsAdmin(String username, bool isAdmin) async {
    await DB._database.update(
      "users",
      {"isAdmin": isAdmin ? 1 : 0},
      where: "username = ?",
      whereArgs: [username]
    );
  }

  /// Creates user from passed info
  Future<void> addUser(String username, String password, bool isAdmin) async {
    await DB._database.insert(
      "users",
      {
        "username": username,
        "password": password,
        "isAdmin": isAdmin ? 1 : 0
      }
    );
  }

  /// Deletes the passed user from the database
  Future<void> deleteUser(String username) async {
    await DB._database.delete(
      "users",
      where: "username = ?",
      whereArgs: [username]
    );
  }
}