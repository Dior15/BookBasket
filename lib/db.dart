import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DB {
  static final DB _db = DB();
  static late Database _database;
  static bool _isInitialized = false;

  /// Call this static method to get an object that can access the database interaction methods
  static Future<DB> getReference() async {
    if (!_isInitialized) {
      String dbPath = await getDatabasesPath();
      String path = p.join(dbPath, 'BookBasket.db');
      DB._database = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('CREATE TABLE users(username STRING PRIMARY KEY, password STRING, isAdmin BOOLEAN)');
        }
      );
      _isInitialized = true;
    }
    // await _db.insertDemoData();
    return(DB._db);
  }

  Future<bool> validateLogin(String username, String password) async {
    List<Map<String, Object?>> user = await _database.query(
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
    List<Map<String, Object?>> user = await _database.query(
        "users",
        where: "username = ?",
        whereArgs: [username]
    );
    return(user.isNotEmpty && user.first["isAdmin"] == 1); // REMEMBER THAT SQFLITE STORES BOOLEANS AS 0 OR 1
  }

  Future<void> insertDemoData() async {
    await _database.insert(
      "users",
      {
        "username":"admin@bookbasket.com",
        "password":"admin123",
        "isAdmin":true
      }
    );
    await _database.insert(
      "users",
      {
        "username":"user@bookbasket.com",
        "password":"user123",
        "isAdmin":false
      }
    );
  }
}