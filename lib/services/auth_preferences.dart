import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthPreferences {
  static const _keyIsLoggedIn = 'is_logged_in';
  static const _keyUsername = 'username';
  static const _keyUsers = 'users_data';

  static Future<void> saveLogin(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUsername, username);
  }

  static Future<bool> getLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUsername);
  }

  static Future<Map<String, String>> getRegisteredUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyUsers);
    if (jsonString == null) return {};
    return Map<String, String>.from(json.decode(jsonString));
  }

  static Future<void> registerUser(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await getRegisteredUsers();
    users[username] = password;
    await prefs.setString(_keyUsers, json.encode(users));
  }

  static Future<bool> validateUser(String username, String password) async {
    final users = await getRegisteredUsers();
    return users[username] == password;
  }
}
