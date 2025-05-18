import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static const _boxName = 'users';
  static const _keyIsLoggedIn = 'is_logged_in';
  static const _keyUsername = 'username';

  static Box<User> getUserBox() => Hive.box<User>(_boxName);

  // Register user ke Hive
  static Future<void> registerUser(String username, String password) async {
    final box = getUserBox();
    final exists = box.values.any((u) => u.username == username);
    if (exists) {
      throw Exception('Username sudah terdaftar');
    }
    final newUser = User(username: username, password: password);
    await box.add(newUser);
  }

  // Validasi login dari Hive
  static bool validateUser(String username, String password) {
    final box = getUserBox();
    try {
      final user = box.values.firstWhere((u) => u.username == username);
      return user.password == password;
    } catch (_) {
      return false;
    }
  }

  // Simpan status login di Shared Preferences
  static Future<void> saveLoginStatus(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUsername, username);
  }

  // Ambil status login dari Shared Preferences
  static Future<bool> getLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  // Logout dan hapus status login
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUsername);
  }
}
