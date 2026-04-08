part of "firebase_db.dart";

extension Books on FirebaseDB {
  /// Returns a list containing all the books in the database
  Future<List<Map<String,dynamic>>> getBooks() async {
    QuerySnapshot<Map<String, dynamic>> query = await FirebaseDB._database
        .collection("books")
        .orderBy("title")
        .get();

    return query.docs.map((document) {
      return document.data();
    }).toList();
  }

  /// Returns a list of strings containing the file names of books in the database
  Future<List<String>> getBookFileNames() async {
    QuerySnapshot<Map<String, dynamic>> query = await FirebaseDB._database
        .collection("books")
        .orderBy("title")
        .get();

    return query.docs.map((document) {
      return document.data()["fileName"].toString();
    }).toList();
  }

  /// Pass information as parameters, ensure that the epub file exists too
  Future<void> addNewBook(String title, String author, String fileName) async {
    await FirebaseDB._database
        .collection("books")
        .add({"title": title, "author": author, "fileName": fileName, "isBorrowed": 0});
  }

  /// Pass an epub file name to check its availability, receive boolean
  Future<bool> isAvailableByFileName(String fileName) async {
    QuerySnapshot<Map<String, dynamic>> query = await FirebaseDB._database
        .collection("books")
        .where("fileName", isEqualTo: fileName)
        .limit(1)
        .get();

    if (query.docs.first.exists) {
      return(query.docs.first.data()["isAvailable"]);
    }
    return(false);
  }

  /// Pass search bar text, receive list of book file names that can be used to display them as search results
  Future<List<String>> getBookByTitle(String title) async {
    QuerySnapshot<Map<String, dynamic>> query = await FirebaseDB._database
        .collection("books")
        .where("titleLower", isGreaterThanOrEqualTo: title.toLowerCase())
        .where("titleLower", isLessThan: '${title.toLowerCase()}z')
        .get();

    return query.docs.map((document) {
      return document.data()["fileName"].toString();
    }).toList();
  }

  /// Pass search bar text, receive full book detail maps for the search UI.
  /// Each map contains: title, author, fileName, isBorrowed (bool).
  /// Borrow status is read from the books collection's [isBorrowed] field,
  /// which is kept in sync by the checkout/checkin transactions.
  Future<List<Map<String, dynamic>>> getBooksByTitle(String title) async {
    final String normalizedQuery = title.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return [];

    // Fetch books in title order, then apply local substring matching.
    // Firestore supports prefix filtering, but not full "contains" matching.
    final QuerySnapshot<Map<String, dynamic>> booksQuery =
        await FirebaseDB._database
            .collection("books")
            .orderBy("titleLower")
            .get();

    final matchedDocs = booksQuery.docs.where((doc) {
      final data = doc.data();
      final titleValue = (data["title"] ?? "").toString().toLowerCase();
      final authorValue = (data["author"] ?? "").toString().toLowerCase();
      final fileNameValue = (data["fileName"] ?? "").toString().toLowerCase();
      return titleValue.contains(normalizedQuery) ||
          authorValue.contains(normalizedQuery) ||
          fileNameValue.contains(normalizedQuery);
    }).toList();

    if (matchedDocs.isEmpty) return [];

    // Collect all matched fileNames so we can cross-check bookCheckout.
    final List<String> fileNames = matchedDocs
        .map((d) => d.data()["fileName"].toString())
        .toList();

    // Fetch active checkout records for these books in one query.
    // Firestore "whereIn" supports up to 30 items; chunk if needed.
    final Set<String> borrowedFileNames = {};
    const int chunkSize = 30;
    for (int i = 0; i < fileNames.length; i += chunkSize) {
      final chunk = fileNames.sublist(
          i, i + chunkSize > fileNames.length ? fileNames.length : i + chunkSize);
      final QuerySnapshot checkoutQuery = await FirebaseDB._database
          .collection("bookCheckout")
          .where("fileName", whereIn: chunk)
          .get();
      for (final doc in checkoutQuery.docs) {
        borrowedFileNames.add(doc["fileName"].toString());
      }
    }

    // Build result list, using the checkout set as the authoritative source
    // for borrow status (mirrors what the books.isBorrowed field should show).
    return matchedDocs.map((doc) {
      final data = doc.data();
      final String fileName = data["fileName"]?.toString() ?? "";
      return <String, dynamic>{
        "title": data["title"] ?? "",
        "author": data["author"] ?? "",
        "fileName": fileName,
        "isBorrowed": borrowedFileNames.contains(fileName),
      };
    }).toList();
  }
}