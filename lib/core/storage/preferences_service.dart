import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class PreferencesService {
  ThemeMode getThemeMode();
  Future<void> setThemeMode(ThemeMode mode);
  Locale? getLocale();
  Future<void> setLocale(Locale? locale);
  bool getLectureRemindersEnabled();
  Future<void> setLectureRemindersEnabled(bool enabled);
  bool getTaskRemindersEnabled();
  Future<void> setTaskRemindersEnabled(bool enabled);
}

class PreferencesServiceImpl implements PreferencesService {
  final SharedPreferences _prefs;

  static const String _keyThemeMode = 'app_theme_mode';
  static const String _keyLanguageCode = 'app_language_code';
  static const String _keyLectureReminders = 'app_lecture_reminders_enabled';
  static const String _keyTaskReminders = 'app_task_reminders_enabled';

  PreferencesServiceImpl(this._prefs);

  @override
  bool getLectureRemindersEnabled() {
    return _prefs.getBool(_keyLectureReminders) ?? true;
  }

  @override
  Future<void> setLectureRemindersEnabled(bool enabled) async {
    await _prefs.setBool(_keyLectureReminders, enabled);
  }

  @override
  bool getTaskRemindersEnabled() {
    return _prefs.getBool(_keyTaskReminders) ?? true;
  }

  @override
  Future<void> setTaskRemindersEnabled(bool enabled) async {
    await _prefs.setBool(_keyTaskReminders, enabled);
  }

  @override
  ThemeMode getThemeMode() {
    final value = _prefs.getString(_keyThemeMode);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    switch (mode) {
      case ThemeMode.light:
        await _prefs.setString(_keyThemeMode, 'light');
        break;
      case ThemeMode.dark:
        await _prefs.setString(_keyThemeMode, 'dark');
        break;
      case ThemeMode.system:
        await _prefs.setString(_keyThemeMode, 'system');
        break;
    }
  }

  @override
  Locale? getLocale() {
    final languageCode = _prefs.getString(_keyLanguageCode);
    if (languageCode == null || languageCode.isEmpty) {
      return null;
    }
    return Locale(languageCode);
  }

  @override
  Future<void> setLocale(Locale? locale) async {
    if (locale == null) {
      await _prefs.remove(_keyLanguageCode);
    } else {
      await _prefs.setString(_keyLanguageCode, locale.languageCode);
    }
  }
}
