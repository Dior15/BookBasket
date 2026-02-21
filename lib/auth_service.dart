import 'package:shared_preferences/shared_preferences.dart';
import 'db.dart';

class AuthService {
  static const _kLoggedIn = 'logged_in';
  static const _kEmail = 'email';
  static const _kIsAdmin = 'is_admin';

  // Demo credentials - THESE ARE BEING MOVED TO THE DATABASE
  static const String adminEmail = 'admin@bookbasket.com';
  static const String adminPassword = 'admin123';

  static String userEmail = 'user@bookbasket.com';
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

    DB db = await DB.getReference();

    if (await db.validateLogin(e, p)) {
      ok = true;
      userEmail = e;
      if (await db.isAdmin(e)) {
        admin = true;
      }
    }

    // if (e == adminEmail && p == adminPassword) {
    //   ok = true;
    //   admin = true;
    // } else if (e == userEmail && p == userPassword) {
    //   ok = true;
    //   admin = false;
    // } else {
    //   ok = false;
    // }

    if (!ok) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLoggedIn, true);
    await prefs.setString(_kEmail, e);
    await prefs.setBool(_kIsAdmin, admin);
    return true;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLoggedIn);
    await prefs.remove(_kEmail);
    await prefs.remove(_kIsAdmin);
  }
}
