import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/game_models.dart';
import '../services/persistence_service.dart';

class GameStore extends ChangeNotifier {
  GameStore({PersistenceService? persistence})
      : _persistence = persistence ?? PersistenceService();

  final PersistenceService _persistence;

  // -------------------------------------------------------------------------
  // Core state
  // -------------------------------------------------------------------------
  late GameSettings settings;
  final List<DayEntry> days = [];
  final List<Achievement> achievements = [];

  int streak = 0;
  int missedInRow = 0;
  bool initialized = false;

  // -------------------------------------------------------------------------
  // Extended state (new vs. original)
  // -------------------------------------------------------------------------

  /// Show the celebration modal when true.
  bool showCelebration = false;

  /// Game is paused at maximum (cap mode, celebration dismissed).
  bool isPausedAfterMaximum = false;

  /// Draft spend items indexed by dayIndex (unsaved, auto-saved).
  final Map<int, List<SpendItem>> draftItemsByDayIndex = {};

  /// User-created custom category names.
  final List<String> customCategories = [];

  /// Token (color key) assigned to each category name.
  final Map<String, String> customCategoryColors = {};

  /// Persistence error message, shown in UI if non-null.
  String? persistenceError;

  // -------------------------------------------------------------------------
  // Midnight watcher
  // -------------------------------------------------------------------------
  Timer? _midnightTimer;

  // -------------------------------------------------------------------------
  // Default categories per language
  // -------------------------------------------------------------------------
  static const Map<String, List<String>> defaultCategoriesByLanguage = {
    'en': ['Food', 'Transport', 'Entertainment', 'Health', 'Home', 'Shopping', 'Sport', 'Other'],
    'ru': ['Еда', 'Транспорт', 'Развлечения', 'Здоровье', 'Дом', 'Покупки', 'Спорт', 'Прочее'],
    'de': ['Essen', 'Transport', 'Unterhaltung', 'Gesundheit', 'Haushalt', 'Einkauf', 'Sport', 'Sonstiges'],
  };

  // -------------------------------------------------------------------------
  // Init
  // -------------------------------------------------------------------------

  Future<void> init(Locale deviceLocale) async {
    settings = (await _persistence.loadSettings()) ??
        GameSettings.defaults(deviceLocale.languageCode);

    days
      ..clear()
      ..addAll(await _persistence.loadDays());

    achievements
      ..clear()
      ..addAll(await _persistence.loadAchievements());

    final meta = await _persistence.loadProgressMeta();
    streak = meta.$1;
    missedInRow = meta.$2;

    final drafts = await _persistence.loadDrafts();
    draftItemsByDayIndex
      ..clear()
      ..addAll(drafts);

    final categories = await _persistence.loadCustomCategories();
    customCategories
      ..clear()
      ..addAll(categories.$1);
    customCategoryColors
      ..clear()
      ..addAll(categories.$2);

    if (achievements.isEmpty) {
      achievements.addAll([
        Achievement(id: 'streak3', titleKey: 'streak3'),
        Achievement(id: 'streak7', titleKey: 'streak7'),
        Achievement(id: 'streak14', titleKey: 'streak14'),
        Achievement(id: 'streak30', titleKey: 'streak30'),
        Achievement(id: 'perfect', titleKey: 'perfect'),
        Achievement(id: 'maximum', titleKey: 'maximum'),
      ]);
    }

    ensureTodayEntry();
    _startMidnightWatcher();
    initialized = true;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Computed getters
  // -------------------------------------------------------------------------

  /// The entry whose calendar date matches today (local timezone).
  DayEntry? get todayEntry {
    final now = DateTime.now();
    final todayStr = _isoDate(now);
    for (final d in days.reversed) {
      if (d.dateIso.startsWith(todayStr)) return d;
    }
    return days.isEmpty ? null : days.last;
  }

  /// Legacy alias kept for backward compatibility.
  DayEntry get today => todayEntry ?? days.last;

  List<String> get categorySuggestions {
    final defaults = defaultCategoriesByLanguage[settings.languageCode] ??
        defaultCategoriesByLanguage['en']!;
    return [...defaults, ...customCategories];
  }

  // -------------------------------------------------------------------------
  // Ensure today entry (called on init and midnight)
  // -------------------------------------------------------------------------

  void ensureTodayEntry() {
    final now = DateTime.now();
    final todayStr = _isoDate(now);

    // Mark any open days before today as missed
    for (int i = 0; i < days.length; i++) {
      final d = days[i];
      if (d.status == DayStatus.open && !d.dateIso.startsWith(todayStr)) {
        days[i] = d.copyWith(status: DayStatus.missed);
        missedInRow += 1;
        if (missedInRow >= 2) streak = 0;
      }
    }

    // Check if today already exists
    final hasToday = days.any((d) => d.dateIso.startsWith(todayStr));
    if (hasToday) return;

    // Create first-ever entry or next day
    if (days.isEmpty) {
      final lang = settings.languageCode;
      days.add(DayEntry(
        dayIndex: 1,
        dateIso: now.toIso8601String(),
        currencyCode: settings.currencyByLanguage[lang]!,
        dailyLimitMinor: settings.startAmountMinorByLanguage[lang]!,
      ));
      return;
    }

    _createNextDayEntry(now);
  }

  // -------------------------------------------------------------------------
  // Format money
  // -------------------------------------------------------------------------

  String formatMoney(int minor, String currencyCode) {
    final value = minor / 100;
    final formatter = NumberFormat.currency(
      locale: settings.languageCode,
      name: currencyCode,
      decimalDigits: 2,
    );
    return formatter.format(value);
  }

  // -------------------------------------------------------------------------
  // Spend item operations
  // -------------------------------------------------------------------------

  void addSpendItem({
    required String title,
    required int amountMinor,
    String? category,
  }) {
    today.items.add(SpendItem(title: title, amountMinor: amountMinor, category: category));
    _saveAll();
    notifyListeners();
  }

  void removeSpendItem(int index) {
    today.items.removeAt(index);
    _saveAll();
    notifyListeners();
  }

  /// Save spends for any day by index (supports editing historical days).
  void saveSpends(List<SpendItem> items, int dayIndex) {
    final idx = days.indexWhere((d) => d.dayIndex == dayIndex);
    if (idx < 0) return;
    final d = days[idx];
    days[idx] = d.copyWith(items: List.of(items));
    _saveAll();
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Draft operations
  // -------------------------------------------------------------------------

  List<SpendItem> draftItems(int dayIndex) =>
      draftItemsByDayIndex[dayIndex] ?? [];

  void updateDraftItems(List<SpendItem> items, int dayIndex) {
    draftItemsByDayIndex[dayIndex] = List.of(items);
    _persistence.saveDrafts(draftItemsByDayIndex);
  }

  void clearDraft(int dayIndex) {
    draftItemsByDayIndex.remove(dayIndex);
    _persistence.saveDrafts(draftItemsByDayIndex);
  }

  // -------------------------------------------------------------------------
  // Save / miss today
  // -------------------------------------------------------------------------

  bool canSaveToday() {
    final t = today;
    final overLimit = t.totalSpent > t.allowedTotalMinor;
    return !overLimit && t.items.isNotEmpty;
  }

  void saveToday() {
    if (!canSaveToday()) return;
    today.status = DayStatus.filled;
    streak += 1;
    missedInRow = 0;

    if (today.totalSpent == today.dailyLimitMinor) _earn('perfect');
    if (streak >= 3) _earn('streak3');
    if (streak >= 7) _earn('streak7');
    if (streak >= 14) _earn('streak14');
    if (streak >= 30) _earn('streak30');

    // Check if max reached — show celebration now; next day is created at midnight
    final lang = settings.languageCode;
    final maxForLanguage = settings.maxAmountMinorByLanguage[lang]!;
    if (today.dailyLimitMinor >= maxForLanguage) {
      _earn('maximum');
      if (settings.maxBehavior == MaxBehavior.cap) {
        showCelebration = true;
        isPausedAfterMaximum = true;
      }
    }

    clearDraft(today.dayIndex);
    _saveAll();
    notifyListeners();
  }

  void markMissedDay() {
    if (today.status == DayStatus.open) {
      today.status = DayStatus.missed;
    }
    missedInRow += 1;
    if (missedInRow >= 2) streak = 0;
    _saveAll();
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Celebration
  // -------------------------------------------------------------------------

  void dismissCelebration() {
    showCelebration = false;
    notifyListeners();
  }

  void clearPersistenceError() {
    persistenceError = null;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Restart game
  // -------------------------------------------------------------------------

  Future<void> restartGame() async {
    days.clear();
    achievements
      ..clear()
      ..addAll([
        Achievement(id: 'streak3', titleKey: 'streak3'),
        Achievement(id: 'streak7', titleKey: 'streak7'),
        Achievement(id: 'streak14', titleKey: 'streak14'),
        Achievement(id: 'streak30', titleKey: 'streak30'),
        Achievement(id: 'perfect', titleKey: 'perfect'),
        Achievement(id: 'maximum', titleKey: 'maximum'),
      ]);
    streak = 0;
    missedInRow = 0;
    showCelebration = false;
    isPausedAfterMaximum = false;
    draftItemsByDayIndex.clear();
    ensureTodayEntry();
    await _persistence.clearAll();
    _saveAll();
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Language / settings
  // -------------------------------------------------------------------------

  void switchLanguage(String languageCode) {
    final fromCurrency = settings.currencyByLanguage[settings.languageCode]!;
    final toCurrency = settings.currencyByLanguage[languageCode]!;
    final rate = _fxRate(fromCurrency, toCurrency);

    settings = settings.copyWith(languageCode: languageCode);

    if (today.status != DayStatus.open) {
      final converted = (today.dailyLimitMinor * rate).round();
      final limit = _capForLanguage(languageCode, converted);
      days.add(DayEntry(
        dayIndex: days.length + 1,
        dateIso: DateTime.now().toIso8601String(),
        currencyCode: toCurrency,
        dailyLimitMinor: limit,
        conversionRateUsed: rate,
      ));
    } else {
      final converted = (today.dailyLimitMinor * rate).round();
      days[days.length - 1] = DayEntry(
        dayIndex: today.dayIndex,
        dateIso: today.dateIso,
        currencyCode: toCurrency,
        dailyLimitMinor: _capForLanguage(languageCode, converted),
        conversionRateUsed: rate,
      );
    }

    _saveAll();
    notifyListeners();
  }

  void updateMaxBehavior(MaxBehavior behavior) {
    settings = settings.copyWith(maxBehavior: behavior);
    _saveAll();
    notifyListeners();
  }

  void updateSettings(GameSettings newSettings) {
    settings = newSettings;
    _saveAll();
    notifyListeners();
  }

  void updateOnboardingShown(bool value) {
    settings = settings.copyWith(onboardingShown: value);
    _saveAll();
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Custom categories
  // -------------------------------------------------------------------------

  void addCustomCategory(String name) {
    if (customCategories.contains(name)) return;
    customCategories.add(name);
    customCategoryColors[name] = CategoryPalette.fallbackToken(name);
    _persistence.saveCustomCategories(customCategories, customCategoryColors);
    notifyListeners();
  }

  void removeCustomCategory(String name) {
    customCategories.remove(name);
    customCategoryColors.remove(name);
    _persistence.saveCustomCategories(customCategories, customCategoryColors);
    notifyListeners();
  }

  void renameCustomCategory(String oldName, String newName) {
    if (!customCategories.contains(oldName)) return;
    final idx = customCategories.indexOf(oldName);
    customCategories[idx] = newName;
    final color = customCategoryColors.remove(oldName);
    if (color != null) customCategoryColors[newName] = color;
    // Update existing spend items
    for (final day in days) {
      for (int i = 0; i < day.items.length; i++) {
        if (day.items[i].category == oldName) {
          day.items[i] = day.items[i].copyWith(category: newName);
        }
      }
    }
    _persistence.saveCustomCategories(customCategories, customCategoryColors);
    _saveAll();
    notifyListeners();
  }

  void cycleCustomCategoryColor(String name) {
    final current = customCategoryColors[name];
    customCategoryColors[name] = CategoryPalette.nextToken(current);
    _persistence.saveCustomCategories(customCategories, customCategoryColors);
    notifyListeners();
  }

  String colorTokenForCategory(String name) {
    return customCategoryColors[name] ?? CategoryPalette.fallbackToken(name);
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  void _createNextDayIfNeeded() {
    final t = today;
    if (t.status == DayStatus.open) return;
    _createNextDayEntry(DateTime.now());
  }

  void _createNextDayEntry(DateTime now) {
    final language = settings.languageCode;
    final currency = settings.currencyByLanguage[language]!;
    final maxForLanguage = settings.maxAmountMinorByLanguage[language]!;

    final lastFilled = days.lastWhere(
      (d) => d.status == DayStatus.filled,
      orElse: () => days.last,
    );

    int nextLimit;
    if (lastFilled.dailyLimitMinor >= maxForLanguage) {
      _earn('maximum');
      if (settings.maxBehavior == MaxBehavior.reset) {
        nextLimit = settings.startAmountMinorByLanguage[language]!;
      } else {
        nextLimit = maxForLanguage;
        isPausedAfterMaximum = true;
        showCelebration = true;
      }
    } else if (days.last.status == DayStatus.missed && missedInRow >= 2) {
      // Streak reset: back to start
      nextLimit = settings.startAmountMinorByLanguage[language]!;
    } else if (days.last.status == DayStatus.filled) {
      nextLimit = min(maxForLanguage, days.last.dailyLimitMinor * 2);
    } else {
      nextLimit = days.last.dailyLimitMinor;
    }

    days.add(DayEntry(
      dayIndex: days.length + 1,
      dateIso: now.toIso8601String(),
      currencyCode: currency,
      dailyLimitMinor: nextLimit,
    ));
  }

  double _fxRate(String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return 1;
    final key = '${fromCurrency}_$toCurrency';
    return settings.approxFxTable[key] ?? 1;
  }

  int _capForLanguage(String languageCode, int candidate) {
    final max = settings.maxAmountMinorByLanguage[languageCode]!;
    return min(candidate, max);
  }

  void _earn(String id) {
    final idx = achievements.indexWhere((item) => item.id == id);
    if (idx < 0) return;
    achievements[idx].earnedAtIso ??= DateTime.now().toIso8601String();
  }

  Future<void> _saveAll() async {
    try {
      await _persistence.saveSettings(settings);
      await _persistence.saveDays(days);
      await _persistence.saveAchievements(achievements);
      await _persistence.saveProgressMeta(streak: streak, misses: missedInRow);
      persistenceError = null;
    } catch (e) {
      persistenceError = e.toString();
      notifyListeners();
    }
  }

  // -------------------------------------------------------------------------
  // Midnight watcher
  // -------------------------------------------------------------------------

  void _startMidnightWatcher() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final delay = nextMidnight.difference(now);

    _midnightTimer = Timer(delay, () {
      ensureTodayEntry();
      _saveAll();
      notifyListeners();
      _startMidnightWatcher(); // Reschedule for next midnight
    });
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  static String _isoDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }
}
