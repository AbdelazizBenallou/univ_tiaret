import 'package:shared_preferences/shared_preferences.dart';

class ThemePreferences {
  static const _key = 'theme_mode';

  static Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? 'system';
  }

  static Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode);
  }
}
