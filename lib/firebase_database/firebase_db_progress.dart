part of "firebase_db.dart";

extension Progress on FirebaseDB {
  /// Fetches the last read page for a specific user and book
  Future<int> getReadingProgress(String username, String bookTitle) async {
    final query = await FirebaseDB._database
        .collection("progress")
        .where("username", isEqualTo: username)
        .where("bookTitle", isEqualTo: bookTitle)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first["currentPage"] as int;
    }
    return 0; // If they haven't started the book, start at page 0
  }

  /// Saves the current page to the cloud
  Future<void> saveReadingProgress(String username, String bookTitle, int currentPage) async {
    final query = await FirebaseDB._database
        .collection("progress")
        .where("username", isEqualTo: username)
        .where("bookTitle", isEqualTo: bookTitle)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      // If a record exists, just update the page number and timestamp
      await FirebaseDB._database
          .collection("progress")
          .doc(query.docs.first.id)
          .update({
        "currentPage": currentPage,
        "lastUpdated": DateTime.now().toIso8601String()
      });
    } else {
      // If this is their first time opening the book, create a new record
      await FirebaseDB._database
          .collection("progress")
          .add({
        "username": username,
        "bookTitle": bookTitle,
        "currentPage": currentPage,
        "lastUpdated": DateTime.now().toIso8601String(),
      });
    }
  }
}