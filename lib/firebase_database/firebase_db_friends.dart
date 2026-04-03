part of "firebase_db.dart";

// A USER SHOULD ALWAYS BE FRIENDS WITH THEMSELVES TO ENSURE THAT THE FRIEND
//  FIELD EXISTS AND DOESN'T BREAK THE FRIEND LIST PAGE

// ENSURE ALL THE FIELDS ARE POPULATED SO THAT THE FRIEND PAGE DOESN'T BREAK
//  FROM TRYING TO RENDER MISSING FIELDS

extension Friends on FirebaseDB {
  /// Receive the dictionary with all of a user's friend information
  Future<Map<String, dynamic>> getFriendInfo(String username) async {
    QuerySnapshot<Map<String, dynamic>> query = await FirebaseDB._database
        .collection("friends")
        .where("username", isEqualTo: username)
        .limit(1)
        .get();

    return {
      "username": query.docs.first["username"],
      "lastReadBook": query.docs.first["lastReadBook"],
      "lastReadOn": query.docs.first["lastReadOn"].toDate().toString().substring(0, 10),
      "friends": query.docs.first["friends"]
    };
  }


}