import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }

  ThemeData get lightTheme =>
      ThemeData(brightness: Brightness.light, fontFamily: 'Poppins');

  ThemeData get darkTheme =>
      ThemeData(brightness: Brightness.dark, fontFamily: 'Poppins');
}
