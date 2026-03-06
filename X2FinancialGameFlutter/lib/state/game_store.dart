import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/game_models.dart';
import '../services/persistence_service.dart';

class GameStore extends ChangeNotifier {
  GameStore({PersistenceService? persistence})
      : _persistence = persistence ?? PersistenceService();

  final PersistenceService _persistence;

  late GameSettings settings;
  final List<DayEntry> days = [];
  final List<Achievement> achievements = [];

  int streak = 0;
  int missedInRow = 0;
  bool initialized = false;

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
    streak = meta.streak;
    missedInRow = meta.misses;

    if (achievements.isEmpty) {
      achievements.addAll([
        Achievement(id: 'streak3', titleKey: 'streak3'),
        Achievement(id: 'streak7', titleKey: 'streak7'),
        Achievement(id: 'streak14', titleKey: 'streak14'),
        Achievement(id: 'perfect', titleKey: 'perfect'),
        Achievement(id: 'maximum', titleKey: 'maximum'),
      ]);
    }

    _ensureTodayEntry();
    initialized = true;
    notifyListeners();
  }

  DayEntry get today => days.last;

  String formatMoney(int minor, String currencyCode) {
    final value = minor / 100;
    final formatter = NumberFormat.currency(
      locale: settings.languageCode,
      name: currencyCode,
      decimalDigits: 2,
    );
    return formatter.format(value);
  }

  void addSpendItem({required String title, required int amountMinor, String? category}) {
    today.items.add(SpendItem(title: title, amountMinor: amountMinor, category: category));
    _saveAll();
    notifyListeners();
  }

  void removeSpendItem(int index) {
    today.items.removeAt(index);
    _saveAll();
    notifyListeners();
  }

  bool canSaveToday() {
    final overLimit = today.totalSpent > (today.dailyLimitMinor * 1.05).round();
    return !overLimit && today.items.isNotEmpty;
  }

  void saveToday() {
    if (!canSaveToday()) return;
    today.status = DayStatus.filled;
    streak += 1;
    missedInRow = 0;

    if (today.totalSpent == today.dailyLimitMinor) {
      _earn('perfect');
    }
    if (streak >= 3) _earn('streak3');
    if (streak >= 7) _earn('streak7');
    if (streak >= 14) _earn('streak14');

    _createNextDayIfNeeded();
    _saveAll();
    notifyListeners();
  }

  void markMissedDay() {
    if (today.status == DayStatus.pending) {
      today.status = DayStatus.missed;
    }
    missedInRow += 1;
    if (missedInRow >= 2) {
      streak = 0;
    }
    _createNextDayIfNeeded();
    _saveAll();
    notifyListeners();
  }

  void switchLanguage(String languageCode) {
    final fromCurrency = settings.currencyByLanguage[settings.languageCode]!;
    final toCurrency = settings.currencyByLanguage[languageCode]!;
    final rate = _fxRate(fromCurrency, toCurrency);

    settings = settings.copyWith(languageCode: languageCode);

    if (today.status != DayStatus.pending) {
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
        status: DayStatus.pending,
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

  void _ensureTodayEntry() {
    if (days.isEmpty) {
      final lang = settings.languageCode;
      final start = settings.startAmountMinorByLanguage[lang]!;
      days.add(DayEntry(
        dayIndex: 1,
        dateIso: DateTime.now().toIso8601String(),
        currencyCode: settings.currencyByLanguage[lang]!,
        dailyLimitMinor: start,
      ));
    }
  }

  void _createNextDayIfNeeded() {
    if (today.status == DayStatus.pending) return;
    final language = settings.languageCode;
    final currency = settings.currencyByLanguage[language]!;
    final maxForLanguage = settings.maxAmountMinorByLanguage[language]!;

    int nextLimit = today.dailyLimitMinor;
    if (today.dailyLimitMinor >= maxForLanguage) {
      _earn('maximum');
      nextLimit = settings.maxBehavior == MaxBehavior.reset
          ? settings.startAmountMinorByLanguage[language]!
          : maxForLanguage;
    } else {
      nextLimit = min(maxForLanguage, today.dailyLimitMinor * 2);
    }

    days.add(DayEntry(
      dayIndex: days.length + 1,
      dateIso: DateTime.now().toIso8601String(),
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
    final achievement = achievements.firstWhere((item) => item.id == id);
    achievement.earnedAtIso ??= DateTime.now().toIso8601String();
  }

  Future<void> _saveAll() async {
    await _persistence.saveSettings(settings);
    await _persistence.saveDays(days);
    await _persistence.saveAchievements(achievements);
    await _persistence.saveProgressMeta(streak: streak, misses: missedInRow);
  }
}
