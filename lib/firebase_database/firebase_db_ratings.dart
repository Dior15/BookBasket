part of "firebase_db.dart";

extension Ratings on FirebaseDB {
  /// Returns the document ID used for a user+book rating pair.
  String _ratingDocId(String username, String fileName) =>
      "${username}_$fileName";

  /// Fetches the current user's rating for [fileName].
  /// Returns null if the user has not rated it yet.
  Future<int?> getUserRating(String username, String fileName) async {
    final doc = await FirebaseDB._database
        .collection("ratings")
        .doc(_ratingDocId(username, fileName))
        .get();

    if (doc.exists) {
      return (doc.data()?["rating"] as num?)?.toInt();
    }
    return null;
  }

  /// Saves (or overwrites) the user's rating for [fileName].
  Future<void> setUserRating(
      String username, String fileName, int rating) async {
    await FirebaseDB._database
        .collection("ratings")
        .doc(_ratingDocId(username, fileName))
        .set({
      "username": username,
      "fileName": fileName,
      "rating": rating,
      "timestamp": FieldValue.serverTimestamp(),
    });
  }

  /// Removes the user's rating for [fileName].
  Future<void> deleteUserRating(String username, String fileName) async {
    await FirebaseDB._database
        .collection("ratings")
        .doc(_ratingDocId(username, fileName))
        .delete();
  }

  /// Computes the global average rating for [fileName] across all users.
  /// Returns null if no one has rated it yet.
  Future<double?> getAverageRating(String fileName) async {
    final query = await FirebaseDB._database
        .collection("ratings")
        .where("fileName", isEqualTo: fileName)
        .get();

    if (query.docs.isEmpty) return null;

    final total = query.docs.fold<int>(
        0, (acc, doc) => acc + ((doc.data()["rating"] as num?)?.toInt() ?? 0));
    return total / query.docs.length;
  }
}
