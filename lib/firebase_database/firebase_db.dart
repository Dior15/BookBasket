library;

import "package:cloud_firestore/cloud_firestore.dart";

part "firebase_db_users.dart";
part "firebase_db_books.dart";

class FirebaseDB {
  static final FirebaseDB _db = FirebaseDB();
  static final FirebaseFirestore _database = FirebaseFirestore.instance;

  static FirebaseDB getReference() {
    return _db;
  }
}