part of 'db.dart';

extension BookCheckout on DB {
  /// Pass the current username and book being checkout out, receive the id of the checkout record
  Future<int?> checkOutBook(String username, String filename) async {
    if (await DB._db.isAvailableByFileName(filename)) {
      return await DB._database.transaction((transaction) async {
        await transaction.update(
            "books",
            {"isBorrowed": 1},
            where: "fileName = ?",
            whereArgs: [filename]
        );

        return await transaction.insert(
            "bookCheckout",
            {
              "fileName": filename,
              "username": username
            }
        );
      });
    }
    return(null); // Returns null when it fails to checkout
  }

  /// Pass the id of the checkout record to be deleted
  Future<void> checkInBook(int checkOutID) async {
    await DB._database.transaction((transaction) async {
      List<Map<String, Object?>> checkoutRecord = await transaction.query(
        "bookCheckout",
        where: "checkOutID = ?",
        whereArgs: [checkOutID]
      );

      if (checkoutRecord.isEmpty) return;

      await transaction.delete(
        "bookCheckout",
        where: "checkOutID = ?",
        whereArgs: [checkOutID]
      );

      await transaction.update(
        "books",
        {"isBorrowed": 0},
        where: "fileName = ?",
        whereArgs: [checkoutRecord.first["fileName"].toString()]
      );
    });
  }

  /// Pass the current username, receive their basket contents
  Future<List<String>> getBasketContents(String username) async {
    List<Map<String, Object?>> result = await DB._database.query(
      "bookCheckout",
      columns: ["fileName"],
      where: "username = ?",
      whereArgs: [username]
    );

    List<String> fileNames = [];
    for (Map<String, Object?> book in result) {
      fileNames.add(book["fileName"] as String);
    }
    print(fileNames);
    return(fileNames);
  }
}