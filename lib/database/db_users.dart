part of 'db.dart';

extension Users on DB {
  Future<bool> validateLogin(String username, String password) async {
    List<Map<String, Object?>> user = await DB._database.query(
        "users",
        where: "username = ?",
        whereArgs: [username]
    );
    if (user.isNotEmpty && user.first["password"] == password) {
      return(true);
    } else {
      return(false);
    }
  }

  Future<bool> isAdmin(String username) async {
    List<Map<String, Object?>> user = await DB._database.query(
        "users",
        where: "username = ?",
        whereArgs: [username]
    );
    return(user.isNotEmpty && user.first["isAdmin"] == 1); // REMEMBER THAT SQFLITE STORES BOOLEANS AS 0 OR 1
  }

  Future<void> changeIsAdmin(String username, bool isAdmin) async {
    await DB._database.update(
      "users",
      {"isAdmin": isAdmin ? 1 : 0},
      where: "username = ?",
      whereArgs: [username]
    );
  }
}