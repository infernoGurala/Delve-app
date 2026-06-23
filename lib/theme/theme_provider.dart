import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'delve_theme.dart';
import 'delve_themes.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'selected_theme';
  static const String _modeKey = 'selected_mode';
  
  DelveTheme _currentTheme = DelveThemes.wisteriaLight;
  
  DelveTheme get currentTheme => _currentTheme;
  bool _shouldSyncToFirestore = true;
  bool get shouldSyncToFirestore => _shouldSyncToFirestore;
  
  ThemeProvider() {
    _loadTheme();
  }
  
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_themeKey);
    final isDark = prefs.getBool(_modeKey) ?? false;
    if (themeName != null) {
      _currentTheme = DelveThemes.getByNameAndMode(themeName, isDark);
      notifyListeners();
    }
  }

  DelveTheme getThemeByNameAndMode(String name, bool isDark) {
    return DelveThemes.getByNameAndMode(name, isDark);
  }
  
  Future<void> setTheme(DelveTheme theme, {bool saveToFirestore = true}) async {
    _shouldSyncToFirestore = saveToFirestore;
    _currentTheme = theme;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme.name);
    await prefs.setBool(_modeKey, theme.isDark);
    
    // Reset flag for next local change
    _shouldSyncToFirestore = true;
  }

  /// Switch the current flower theme to the other mode (dark ↔ light)
  /// while keeping the same flower type.
  Future<void> toggleMode() async {
    final targetDark = !_currentTheme.isDark;
    final newTheme = DelveThemes.getByNameAndMode(_currentTheme.name, targetDark);
    await setTheme(newTheme);
  }
}
