part of "firebase_db.dart";

extension Summaries on FirebaseDB {
  /// Fetches a summary from Firestore. Returns null if it doesn't exist yet.
  Future<String?> getBookSummary(String bookTitle) async {
    final query = await FirebaseDB._database
        .collection("summaries")
        .where("bookTitle", isEqualTo: bookTitle)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first["summaryText"];
    }
    return null;
  }

  /// Saves a newly generated summary to Firestore
  Future<void> saveBookSummary(String bookTitle, String summary) async {
    await FirebaseDB._database
        .collection("summaries")
        .add({
      "bookTitle": bookTitle,
      "summaryText": summary,
      "generatedOn": DateTime.now().toIso8601String(),
    });
  }
}