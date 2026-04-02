part of "firebase_db.dart";

extension Markers on FirebaseDB {
  /// Receive a list of all markers for a specific user
  Future<List<ReadingMarker>> getUserMarkers(String username) async {
    QuerySnapshot<Map<String, dynamic>> query = await FirebaseDB._database
        .collection("markers")
        .where("username", isEqualTo: username)
        .get();

    return query.docs.map((document) {
      // We can use the existing fromMap factory in ReadingMarker
      return ReadingMarker.fromMap(document.data());
    }).toList();
  }

  /// Add a new marker for a specific user
  Future<void> addUserMarker(String username, ReadingMarker marker) async {
    // Convert the marker to a map and inject the username
    Map<String, dynamic> markerData = marker.toMap();
    markerData["username"] = username;

    await FirebaseDB._database
        .collection("markers")
        .add(markerData);
  }

  /// Deletes a specific marker for a user
  /// Since we don't store a unique Firebase ID locally, we match it by the exact timestamp and username.
  Future<void> deleteUserMarker(String username, ReadingMarker marker) async {
    QuerySnapshot<Map<String, dynamic>> query = await FirebaseDB._database
        .collection("markers")
        .where("username", isEqualTo: username)
        .where("timestamp", isEqualTo: marker.timestamp.toIso8601String())
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      await FirebaseDB._database
          .collection("markers")
          .doc(query.docs.first.id)
          .delete();
    }
  }

  /// Optional: Syncs a local list of markers to the database (useful for migrating local data to cloud)
  Future<void> syncLocalMarkersToCloud(String username, List<ReadingMarker> localMarkers) async {
    // First, get the current cloud markers to avoid duplicates
    List<ReadingMarker> cloudMarkers = await getUserMarkers(username);
    Set<String> cloudTimestamps = cloudMarkers.map((m) => m.timestamp.toIso8601String()).toSet();

    for (var marker in localMarkers) {
      if (!cloudTimestamps.contains(marker.timestamp.toIso8601String())) {
        await addUserMarker(username, marker);
      }
    }
  }

  /// Listens to a live stream of all markers for a specific user
  Stream<List<ReadingMarker>> getUserMarkersStream(String username) {
    // Notice we use .snapshots() instead of .get()
    return FirebaseDB._database
        .collection("markers")
        .where("username", isEqualTo: username)
        .snapshots()
        .map((snapshot) {
      // This .map translates the raw Firebase snapshot into your ReadingMarker objects
      return snapshot.docs.map((document) {
        return ReadingMarker.fromMap(document.data());
      }).toList();
    });
  }

}