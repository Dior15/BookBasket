part of 'db.dart';

extension BookCheckout on DB {
  /// Pass the current username and book being checkout out, receive the id of the checkout record
  Future<int?> checkOutBook(String username, String filename) async {
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
}