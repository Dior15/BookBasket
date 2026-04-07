part of "firebase_db.dart";

extension Friends on FirebaseDB {
  Future<DocumentSnapshot<Map<String, dynamic>>?> _friendDocByUsername(
      String username,
      ) async {
    final query = await FirebaseDB._database
        .collection("friends")
        .where("username", isEqualTo: username.trim().toLowerCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return query.docs.first;
  }

  Map<String, dynamic> _friendDocToMap(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data() ?? <String, dynamic>{};
    final lastReadOn = data["lastReadOn"];

    String formattedDate = "";
    if (lastReadOn is Timestamp) {
      formattedDate = lastReadOn.toDate().toString().substring(0, 10);
    }

    return {
      "username": data["username"] ?? "",
      "lastReadBook": data["lastReadBook"] ?? "Nothing Yet",
      "lastReadOn": formattedDate,
      "friends": List<String>.from(data["friends"] ?? const []),
      "incomingRequests": List<String>.from(
        data["incomingRequests"] ?? const [],
      ),
      "outgoingRequests": List<String>.from(
        data["outgoingRequests"] ?? const [],
      ),
    };
  }

  Future<Map<String, dynamic>> getFriendInfo(String username) async {
    final doc = await _friendDocByUsername(username);
    if (doc == null) return {};
    return _friendDocToMap(doc);
  }

  Stream<Map<String, dynamic>> getFriendInfoStream(String username) {
    return FirebaseDB._database
        .collection("friends")
        .where("username", isEqualTo: username.trim().toLowerCase())
        .limit(1)
        .snapshots()
        .map((querySnapshot) {
      if (querySnapshot.docs.isEmpty) return <String, dynamic>{};
      return _friendDocToMap(querySnapshot.docs.first);
    });
  }

  Future<void> updateLastReadBook(String username, String bookTitle) async {
    final friendDoc = await _friendDocByUsername(username);
    if (friendDoc == null) return;

    await FirebaseDB._database.collection("friends").doc(friendDoc.id).update({
      "lastReadBook": bookTitle,
      "lastReadOn": Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<String?> sendFriendRequest(
      String currentUserEmail,
      String friendEmail,
      ) async {
    final current = currentUserEmail.trim().toLowerCase();
    final target = friendEmail.trim().toLowerCase();

    if (target.isEmpty) {
      return "Please enter an email address.";
    }

    if (current == target) {
      return "You can't send yourself a friend request.";
    }

    final currentDoc = await _friendDocByUsername(current);
    if (currentDoc == null) {
      return "Could not find your account. Please log in again.";
    }

    final targetDoc = await _friendDocByUsername(target);
    if (targetDoc == null) {
      return "No user found with that email.";
    }

    final currentData = currentDoc.data() ?? <String, dynamic>{};
    final targetData = targetDoc.data() ?? <String, dynamic>{};

    final currentFriends = List<String>.from(currentData["friends"] ?? const []);
    final incoming = List<String>.from(
      currentData["incomingRequests"] ?? const [],
    );
    final outgoing = List<String>.from(
      currentData["outgoingRequests"] ?? const [],
    );
    final targetIncoming = List<String>.from(
      targetData["incomingRequests"] ?? const [],
    );

    if (currentFriends.contains(target)) {
      return "You are already friends with this user.";
    }

    if (outgoing.contains(target)) {
      return "Friend request already sent.";
    }

    if (incoming.contains(target)) {
      return "This user already sent you a request. Accept it instead.";
    }

    if (targetIncoming.contains(current)) {
      return "Friend request already sent.";
    }

    await FirebaseDB._database.runTransaction((transaction) async {
      transaction.update(
        FirebaseDB._database.collection("friends").doc(currentDoc.id),
        {
          "outgoingRequests": FieldValue.arrayUnion([target]),
        },
      );

      transaction.update(
        FirebaseDB._database.collection("friends").doc(targetDoc.id),
        {
          "incomingRequests": FieldValue.arrayUnion([current]),
        },
      );
    });

    return null;
  }

  Future<String?> acceptFriendRequest(
      String currentUserEmail,
      String requesterEmail,
      ) async {
    final current = currentUserEmail.trim().toLowerCase();
    final requester = requesterEmail.trim().toLowerCase();

    final currentDoc = await _friendDocByUsername(current);
    final requesterDoc = await _friendDocByUsername(requester);

    if (currentDoc == null || requesterDoc == null) {
      return "Could not complete the request. One of the users no longer exists.";
    }

    await FirebaseDB._database.runTransaction((transaction) async {
      transaction.update(
        FirebaseDB._database.collection("friends").doc(currentDoc.id),
        {
          "incomingRequests": FieldValue.arrayRemove([requester]),
          "friends": FieldValue.arrayUnion([requester]),
        },
      );

      transaction.update(
        FirebaseDB._database.collection("friends").doc(requesterDoc.id),
        {
          "outgoingRequests": FieldValue.arrayRemove([current]),
          "friends": FieldValue.arrayUnion([current]),
        },
      );
    });

    return null;
  }

  Future<void> denyFriendRequest(
      String currentUserEmail,
      String requesterEmail,
      ) async {
    final current = currentUserEmail.trim().toLowerCase();
    final requester = requesterEmail.trim().toLowerCase();

    final currentDoc = await _friendDocByUsername(current);
    final requesterDoc = await _friendDocByUsername(requester);

    if (currentDoc == null || requesterDoc == null) return;

    await FirebaseDB._database.runTransaction((transaction) async {
      transaction.update(
        FirebaseDB._database.collection("friends").doc(currentDoc.id),
        {
          "incomingRequests": FieldValue.arrayRemove([requester]),
        },
      );

      transaction.update(
        FirebaseDB._database.collection("friends").doc(requesterDoc.id),
        {
          "outgoingRequests": FieldValue.arrayRemove([current]),
        },
      );
    });
  }

  Future<void> cancelFriendRequest(
      String currentUserEmail,
      String targetEmail,
      ) async {
    final current = currentUserEmail.trim().toLowerCase();
    final target = targetEmail.trim().toLowerCase();

    final currentDoc = await _friendDocByUsername(current);
    final targetDoc = await _friendDocByUsername(target);

    if (currentDoc == null || targetDoc == null) return;

    await FirebaseDB._database.runTransaction((transaction) async {
      transaction.update(
        FirebaseDB._database.collection("friends").doc(currentDoc.id),
        {
          "outgoingRequests": FieldValue.arrayRemove([target]),
        },
      );

      transaction.update(
        FirebaseDB._database.collection("friends").doc(targetDoc.id),
        {
          "incomingRequests": FieldValue.arrayRemove([current]),
        },
      );
    });
  }

  Future<void> removeFriend(String currentUserEmail, String friendEmail) async {
    final current = currentUserEmail.trim().toLowerCase();
    final target = friendEmail.trim().toLowerCase();

    final currentDoc = await _friendDocByUsername(current);
    final targetDoc = await _friendDocByUsername(target);

    if (currentDoc == null || targetDoc == null) return;

    await FirebaseDB._database.runTransaction((transaction) async {
      transaction.update(
        FirebaseDB._database.collection("friends").doc(currentDoc.id),
        {
          "friends": FieldValue.arrayRemove([target]),
        },
      );

      transaction.update(
        FirebaseDB._database.collection("friends").doc(targetDoc.id),
        {
          "friends": FieldValue.arrayRemove([current]),
        },
      );
    });
  }
}