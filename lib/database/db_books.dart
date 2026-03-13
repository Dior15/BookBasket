part of 'db.dart';

extension Books on DB {
  /// Returns a list containing all the books in the database
  Future<List<Map<String, Object?>>> getBooks() async {
    return await DB._database.query(
      "books"
    );
  }

  /// Returns a list of strings containing the file names of books in the database
  Future<List<String>> getBookFileNames() async {
    List<Map<String, Object?>> books = await DB._database.query(
      "books",
      columns: ["fileName"]
    );
    List<String> fileNames = [];
    for (Map<String, Object?> book in books) {
      fileNames.add(book["fileName"].toString());
    }
    return fileNames;
  }

  /// Pass information as parameters, ensure that the epub file exists too, otherwise things might BREAK
  Future<void> addNewBook(String title, String author, String fileName) async {
    await DB._database.insert(
      "books",
      {
        "title": title,
        "author": author,
        "fileName": fileName,
        "isBorrowed": 0
      }
    );
  }

  /// Pass an epub file name to check its availability, receive boolean
  Future<bool> isAvailableByFileName(String filename) async {
    final result =  await DB._database.query(
      "books",
      columns: ["isBorrowed"],
      where: "filename = ?",
      whereArgs: [filename]
    );
    if (result.isNotEmpty) {
      return(result.first["isBorrowed"] == 0);
    }
    return(false);
  }

  /// Pass search bar, receive list of book file names that can be used to display them as search results
  Future<List<String>> getBookByTitle(String title) async {
    final results = await DB._database.query(
      "books",
      columns: ["fileName"],
      where: "LOWER(title) LIKE LOWER(?)",
      whereArgs: [title]
    );
    List<String> fileNames = [];
    for (Map<String, Object?> fileName in results) {
      fileNames.add(fileName["fileName"].toString());
    }
    return(fileNames);
  }
}