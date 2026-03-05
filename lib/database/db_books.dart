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
}