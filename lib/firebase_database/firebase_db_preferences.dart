part of "firebase_db.dart";

extension Preferences on FirebaseDB {

  /// Fetches all user preferences. If none exist, returns a map of safe defaults.
  Future<Map<String, dynamic>> getUserPreferences(String username) async {
    final docRef = FirebaseDB._database.collection("preferences").doc(username);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists && docSnapshot.data() != null) {
      return docSnapshot.data()!;
    }

    // Fallback defaults if the user hasn't saved any preferences yet
    return {
      "appBackground": "gradient",
      "appForeground": "solid",
      "readerTheme": "light",
      "readerFontSize": 18.0,
      "readerFontFamily": "System Default"
    };
  }

  /// A generic updater that uses 'merge: true' to only update the passed keys
  /// without overwriting the rest of the user's preferences.
  Future<void> updateUserPreference(String username, Map<String, dynamic> newPreferences) async {
    await FirebaseDB._database
        .collection("preferences")
        .doc(username)
    // SetOptions(merge: true) acts like an update, but will safely create
    // the document if this is the user's very first time saving a preference!
        .set(newPreferences, SetOptions(merge: true));
  }

  // --- Convenience Methods ---

  Future<void> saveAppTheme(String username, String background, String foreground) async {
    await updateUserPreference(username, {
      "appBackground": background,
      "appForeground": foreground,
    });
  }

  Future<void> saveReaderSettings(String username, String theme, double fontSize, String fontFamily) async {
    await updateUserPreference(username, {
      "readerTheme": theme,
      "readerFontSize": fontSize,
      "readerFontFamily": fontFamily,
    });
  }
}