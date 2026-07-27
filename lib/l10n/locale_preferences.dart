import 'package:shared_preferences/shared_preferences.dart';

class LocalePreferences {
  static const _key = 'locale_code';

  static Future<String> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? 'en';
  }

  static Future<void> setLocale(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
  }
}
