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
}