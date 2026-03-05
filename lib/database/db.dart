library;
import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

part 'db_books.dart';
part 'db_demo_data.dart';
part 'db_users.dart';

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
          await db.execute('CREATE TABLE books(title STRING NOT NULL, author STRING NOT NULL, fileName STRING, isBorrowed BOOLEAN)');
        }
      );
      _isInitialized = true;
    }
    if (!await _db.isAdmin("admin@bookbasket.com")) { // Inserts demo data if not present in the databases
      _db.insertDemoData();
    }
    // await _db.insertDemoData();
    return(DB._db);
  }
}