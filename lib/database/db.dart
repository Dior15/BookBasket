library;

import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

part 'db_books.dart';
part 'db_demo_data.dart';
part 'db_users.dart';
part 'db_book_checkout.dart';

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
          // This table contains users, their passwords, and whether or not they are an admin
          await db.execute('CREATE TABLE users(username STRING PRIMARY KEY, password STRING, isAdmin BOOLEAN)');
          // This table contains book titles, their authors, their filenames within the file system, and whether or not they have been borrowed by a user
          await db.execute('CREATE TABLE books(bookID INTEGER PRIMARY KEY AUTOINCREMENT, title STRING NOT NULL, author STRING, fileName STRING, isBorrowed BOOLEAN)');
          // This table contains rows containing a user, and a book that they presently have checked out; the user's username and the book's filename act as their unique identifiers
          await db.execute('CREATE TABLE bookCheckout(checkOutID INTEGER PRIMARY KEY AUTOINCREMENT, fileName STRING, username STRING, FOREIGN KEY (fileName) REFERENCES books(fileName), FOREIGN KEY (username) REFERENCES users(username))');
        }
      );
      _isInitialized = true;
    }
    if (!await _db.isAdmin("admin@bookbasket.com")) { // Inserts demo data if not present in the databases
      await _db.insertDemoData();
    }
    // await _db.insertDemoData();
    return(DB._db);
  }
}