library;

import "package:cloud_firestore/cloud_firestore.dart";
import '../map/reading_marker.dart';

part "firebase_db_users.dart";
part "firebase_db_books.dart";
part "firebase_db_checkout.dart";
part "firebase_db_ratings.dart";
part "firebase_db_markers.dart";
part "firebase_db_friends.dart";
part 'firebase_db_progress.dart';

class FirebaseDB {
  static final FirebaseDB _db = FirebaseDB();
  static final FirebaseFirestore _database = FirebaseFirestore.instance;

  static FirebaseDB getReference() {
    return _db;
  }
}