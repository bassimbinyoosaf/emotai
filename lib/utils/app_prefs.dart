import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  static const String firstRunKey = 'first_run';

  /// Call once when app starts
  static Future<void> initFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(firstRunKey)) {
      await prefs.setBool(firstRunKey, true);
    }
  }

  static Future<bool> isFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(firstRunKey) ?? true;
  }

  static Future<void> setFirstRun(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(firstRunKey, value);
  }

  /// Call on logout to clean local flags
  static Future<void> clearLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
