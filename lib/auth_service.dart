import 'package:bookbasket/firebase_database/firebase_db.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart'; // NEW IMPORT
import 'package:google_sign_in/google_sign_in.dart'; // NEW IMPORT

class AuthService {
  static const _kLoggedIn = 'logged_in';
  static const _kEmail = 'email';
  static const _kIsAdmin = 'is_admin';

  // Demo credentials - THESE ARE BEING MOVED TO THE DATABASE
  static const String adminEmail = 'admin@bookbasket.com';
  static const String adminPassword = 'admin123';

  static String userEmail = 'user@bookbasket.com'; // This stores the current logged in user I think
  static String userPassword = 'user123';

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kLoggedIn) ?? false;
  }

  static Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIsAdmin) ?? false;
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kEmail);
  }

  /// Returns true if login succeeded.
  /// - Admin login: admin@bookbasket.com / admin123
  /// - User login:  user@bookbasket.com / user123
  static Future<bool> login(String email, String password) async {
    final e = email.trim().toLowerCase();
    final p = password.trim();

    bool ok = false;
    bool admin = false;

    // DB db = await DB.getReference();
    FirebaseDB db = FirebaseDB.getReference();

    if (await db.validateLogin(e, p)) {
      ok = true;
      userEmail = e;
      if (await db.isAdmin(e)) {
        admin = true;
      }
    }

    if (!ok) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLoggedIn, true);
    await prefs.setString(_kEmail, e);
    await prefs.setBool(_kIsAdmin, admin);
    return true;
  }

  // NEW: Force a local login session for Google Auth
  static Future<void> loginWithGoogle(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLoggedIn, true);
    await prefs.setString(_kEmail, email);

    // We also need to query and save the admin status here so DrawerShell knows!
    FirebaseDB db = FirebaseDB.getReference();
    bool admin = await db.isAdmin(email);
    await prefs.setBool(_kIsAdmin, admin);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // NEW: Explicitly clear the Google and Firebase sessions
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
    } catch (e) {
      // It's safe to silently fail here if they weren't logged in via Google
    }
  }
}