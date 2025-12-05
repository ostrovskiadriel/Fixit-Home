import 'package:flutter/material.dart';
import 'package:fixit_home/services/prefs_service.dart';

/// Controller for app theme. Loads and persists preference via PrefsService.
class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;
  bool get isDarkMode => _mode == ThemeMode.dark;
  bool get isSystemMode => _mode == ThemeMode.system;

  /// Load saved mode from PrefsService. Call before runApp().
  Future<void> load() async {
    final saved = await PrefsService.getThemeMode();
    _mode = _stringToThemeMode(saved);
  }

  Future<void> setMode(ThemeMode newMode) async {
    if (_mode != newMode) {
      _mode = newMode;
      await PrefsService.setThemeMode(_themeModeToString(newMode));
      notifyListeners();
    }
  }

  /// Toggle between light/dark. If currently 'system', invert based on current brightness.
  Future<void> toggle(Brightness currentBrightness) async {
    ThemeMode newMode;
    if (_mode == ThemeMode.system) {
      newMode = currentBrightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    } else {
      newMode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    }
    await setMode(newMode);
  }

  ThemeMode _stringToThemeMode(String v) {
    switch (v) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
