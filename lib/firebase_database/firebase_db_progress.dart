part of "firebase_db.dart";

class ReadingProgress {
  final int currentPage;
  final int? currentSectionIndex;

  const ReadingProgress({
    required this.currentPage,
    this.currentSectionIndex,
  });
}

extension Progress on FirebaseDB {
  /// Fetches the last read page for a specific user and book
  Future<ReadingProgress> getReadingProgress(
      String username, String bookTitle) async {
    final query = await FirebaseDB._database
        .collection("progress")
        .where("username", isEqualTo: username)
        .where("bookTitle", isEqualTo: bookTitle)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final data = query.docs.first.data();
      final currentPage = (data["currentPage"] as num?)?.toInt() ?? 0;
      final currentSectionIndex = (data["currentSectionIndex"] as num?)?.toInt();
      return ReadingProgress(
        currentPage: currentPage,
        currentSectionIndex: currentSectionIndex,
      );
    }
    // If they haven't started the book, start at page 0.
    return const ReadingProgress(currentPage: 0);
  }

  /// Saves the current page to the cloud
  Future<void> saveReadingProgress(
    String username,
    String bookTitle,
    int currentPage, {
    int? currentSectionIndex,
  }) async {
    final query = await FirebaseDB._database
        .collection("progress")
        .where("username", isEqualTo: username)
        .where("bookTitle", isEqualTo: bookTitle)
        .limit(1)
        .get();

    final payload = {
      "currentPage": currentPage,
      "currentSectionIndex": currentSectionIndex,
      "lastUpdated": DateTime.now().toIso8601String(),
    };

    if (query.docs.isNotEmpty) {
      // If a record exists, just update the page number and timestamp
      await FirebaseDB._database
          .collection("progress")
          .doc(query.docs.first.id)
          .update(payload);
    } else {
      // If this is their first time opening the book, create a new record
      await FirebaseDB._database
          .collection("progress")
          .add({
        "username": username,
        "bookTitle": bookTitle,
        ...payload,
      });
    }
  }
}