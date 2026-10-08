import 'package:flutter/material.dart';

/// Global state: Dark/Light theme + user profile name.
class AppState extends ChangeNotifier {
  bool _isDarkMode = false;
  String _userName = 'Student';

  bool get isDarkMode => _isDarkMode;
  String get userName => _userName;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  void setUserName(String name) {
    final trimmed = name.trim();
    _userName = trimmed.isEmpty ? 'Student' : trimmed;
    notifyListeners();
  }
}
