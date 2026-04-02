part of "firebase_db.dart";

extension BookCheckout on FirebaseDB {
  /// Pass the current username and book being checked out, receive the id of the checkout record
  Future<String?> checkOutBook(String username, String fileName) async {
    return await FirebaseDB._database.runTransaction((transaction) async {
      // Get document reference
      final QuerySnapshot query = await FirebaseDB._database
          .collection("books")
          .where("fileName", isEqualTo: fileName)
          .limit(1)
          .get();

      // Check if document exists before proceeding
      if (query.docs.isEmpty) return(null);

      // Check availability within transaction
      final bookSnapshot = await transaction.get(query.docs.first.reference);
      final bool isBorrowed = bookSnapshot["isBorrowed"];

      if (isBorrowed) {
        final checkoutRecordSnapshot = await FirebaseDB._database
          .collection("bookCheckout")
          .where("fileName", isEqualTo: fileName)
          .limit(1)
          .get();
        final checkoutRecordSnapshotT = await transaction.get(checkoutRecordSnapshot.docs.first.reference);

        // Check if the current date is after the current checkout's expiration
        if (DateTime.now().isAfter(checkoutRecordSnapshotT["checkoutExpiry"].toDate())) {
          transaction.delete(checkoutRecordSnapshotT.reference);
        } else {
          return(null);
        }
      }

      // Update isBorrowed field for book
      transaction.update(bookSnapshot.reference, {"isBorrowed": true});

      // Create checkout record
      final checkoutDocument = FirebaseDB._database.collection("bookCheckout").doc();
      transaction.set(
        checkoutDocument,
        {
          "fileName": fileName,
          "username": username,
          "checkoutExpiry": Timestamp.fromDate(DateTime.now().add(Duration(days: 14)))
        }
      );

      // Return checkout document id
      return(checkoutDocument.id);
    });
  }

  /// Pass the id of the checkout record to be deleted
  Future<void> checkInBook(String username, String fileName) async {
    await FirebaseDB._database.runTransaction((transaction) async {
      final QuerySnapshot book = await FirebaseDB._database
        .collection("books")
        .where("fileName", isEqualTo: fileName)
        .limit(1)
        .get();
      final QuerySnapshot checkoutRecord = await FirebaseDB._database
        .collection("bookCheckout")
        .where("fileName", isEqualTo: fileName)
        .where("username", isEqualTo: username)
        .limit(1)
        .get();

      if (book.docs.isNotEmpty) {
        final bookT = await transaction.get(book.docs.first.reference);
        transaction.update(bookT.reference, {"isBorrowed": false});
      }
      if (checkoutRecord.docs.isNotEmpty) {
        transaction.delete(checkoutRecord.docs.first.reference);
      }
    });
  }

  /// Pass the current username, receive their basket contents
  Future<List<Map<String, dynamic>>> getBasketContents(String username) async {
    QuerySnapshot query = await FirebaseDB._database
        .collection("bookCheckout")
        .where("username", isEqualTo: username)
        .get();

    return query.docs.map((document) {
      return {
        "fileName": document["fileName"].toString(),
        "checkoutExpiry": document["checkoutExpiry"].toDate().toString().substring(0, 10)
      };
    }).toList();
  }
}