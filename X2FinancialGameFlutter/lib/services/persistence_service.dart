import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_models.dart';

class PersistenceService {
  static const _settingsKey = 'x2_settings';
  static const _daysKey = 'x2_days';
  static const _achievementsKey = 'x2_achievements';
  static const _streakKey = 'x2_streak';
  static const _missesKey = 'x2_misses';
  static const _draftsKey = 'x2_drafts';
  static const _customCategoriesKey = 'x2_custom_categories';
  static const _customCategoryColorsKey = 'x2_custom_category_colors';

  // -------------------------------------------------------------------------
  // Settings
  // -------------------------------------------------------------------------

  Future<void> saveSettings(GameSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
    } catch (_) {}
  }

  Future<GameSettings?> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_settingsKey);
      if (raw == null) return null;
      return GameSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // Days
  // -------------------------------------------------------------------------

  Future<void> saveDays(List<DayEntry> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_daysKey, encodeEntries(entries));
    } catch (_) {}
  }

  Future<List<DayEntry>> loadDays() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_daysKey);
      if (raw == null) return [];
      return decodeEntries(raw);
    } catch (_) {
      return [];
    }
  }

  // -------------------------------------------------------------------------
  // Achievements
  // -------------------------------------------------------------------------

  Future<void> saveAchievements(List<Achievement> achievements) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_achievementsKey, encodeAchievements(achievements));
    } catch (_) {}
  }

  Future<List<Achievement>> loadAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_achievementsKey);
      if (raw == null) return [];
      return decodeAchievements(raw);
    } catch (_) {
      return [];
    }
  }

  // -------------------------------------------------------------------------
  // Progress meta (streak + misses)
  // -------------------------------------------------------------------------

  Future<void> saveProgressMeta({required int streak, required int misses}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_streakKey, streak);
      await prefs.setInt(_missesKey, misses);
    } catch (_) {}
  }

  Future<(int, int)> loadProgressMeta() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getInt(_streakKey) ?? 0, prefs.getInt(_missesKey) ?? 0);
    } catch (_) {
      return (0, 0);
    }
  }

  // -------------------------------------------------------------------------
  // Drafts
  // -------------------------------------------------------------------------

  Future<void> saveDrafts(Map<int, List<SpendItem>> drafts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(drafts.map(
        (key, value) => MapEntry(
          key.toString(),
          value.map((item) => item.toJson()).toList(),
        ),
      ));
      await prefs.setString(_draftsKey, encoded);
    } catch (_) {}
  }

  Future<Map<int, List<SpendItem>>> loadDrafts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_draftsKey);
      if (raw == null) return {};
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((key, value) => MapEntry(
            int.parse(key),
            (value as List<dynamic>)
                .map((item) => SpendItem.fromJson(item as Map<String, dynamic>))
                .toList(),
          ));
    } catch (_) {
      return {};
    }
  }

  // -------------------------------------------------------------------------
  // Custom categories
  // -------------------------------------------------------------------------

  Future<void> saveCustomCategories(
    List<String> categories,
    Map<String, String> colors,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_customCategoriesKey, jsonEncode(categories));
      await prefs.setString(_customCategoryColorsKey, jsonEncode(colors));
    } catch (_) {}
  }

  Future<(List<String>, Map<String, String>)> loadCustomCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawCats = prefs.getString(_customCategoriesKey);
      final rawColors = prefs.getString(_customCategoryColorsKey);
      final categories = rawCats == null
          ? <String>[]
          : (jsonDecode(rawCats) as List<dynamic>).cast<String>();
      final colors = rawColors == null
          ? <String, String>{}
          : (jsonDecode(rawColors) as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, v as String));
      return (categories, colors);
    } catch (_) {
      return (<String>[], <String, String>{});
    }
  }

  // -------------------------------------------------------------------------
  // Clear all
  // -------------------------------------------------------------------------

  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_daysKey);
      await prefs.remove(_achievementsKey);
      await prefs.remove(_streakKey);
      await prefs.remove(_missesKey);
      await prefs.remove(_draftsKey);
      await prefs.remove(_customCategoriesKey);
      await prefs.remove(_customCategoryColorsKey);
      // Keep settings (language preference etc.)
    } catch (_) {}
  }
}
