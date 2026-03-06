import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_models.dart';

class PersistenceService {
  static const _settingsKey = 'x2_settings';
  static const _daysKey = 'x2_days';
  static const _achievementsKey = 'x2_achievements';
  static const _streakKey = 'x2_streak';
  static const _missesKey = 'x2_misses';

  Future<void> saveSettings(GameSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  Future<GameSettings?> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey);
    if (raw == null) return null;
    return GameSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveDays(List<DayEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_daysKey, encodeEntries(entries));
  }

  Future<List<DayEntry>> loadDays() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_daysKey);
    if (raw == null) return [];
    return decodeEntries(raw);
  }

  Future<void> saveAchievements(List<Achievement> achievements) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_achievementsKey, encodeAchievements(achievements));
  }

  Future<List<Achievement>> loadAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_achievementsKey);
    if (raw == null) return [];
    return decodeAchievements(raw);
  }

  Future<void> saveProgressMeta({required int streak, required int misses}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_streakKey, streak);
    await prefs.setInt(_missesKey, misses);
  }

  Future<(int streak, int misses)> loadProgressMeta() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt(_streakKey) ?? 0, prefs.getInt(_missesKey) ?? 0);
  }
}
