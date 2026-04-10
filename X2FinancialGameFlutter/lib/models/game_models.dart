import 'dart:convert';

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

/// Status of a calendar day. "open" was previously called "pending" — both
/// values are accepted during JSON deserialization for backward compatibility.
enum DayStatus { filled, missed, open }

enum MaxBehavior { reset, cap }

// ---------------------------------------------------------------------------
// CategoryPalette
// ---------------------------------------------------------------------------

/// 12-color token palette for spend categories, mirroring Swift's enum.
class CategoryPalette {
  CategoryPalette._();

  static const List<String> tokens = [
    'blue', 'green', 'orange', 'pink', 'teal',
    'indigo', 'yellow', 'mint', 'cyan', 'red', 'brown', 'gray',
  ];

  static const Map<String, Color> _colors = {
    'blue':   Color(0xFF4A90D9),
    'green':  Color(0xFF2EC27E),
    'orange': Color(0xFFE8A020),
    'pink':   Color(0xFFE85D9A),
    'teal':   Color(0xFF3AADA8),
    'indigo': Color(0xFF5C5FBA),
    'yellow': Color(0xFFCFAE00),
    'mint':   Color(0xFF2DB09C),
    'cyan':   Color(0xFF1DA7C4),
    'red':    Color(0xFFD94040),
    'brown':  Color(0xFF9B7052),
    'gray':   Color(0xFF808080),
  };

  static Color color(String token) => _colors[token] ?? _colors['blue']!;

  static String nextToken(String? after) {
    if (after == null) return tokens.first;
    final idx = tokens.indexOf(after);
    if (idx < 0) return tokens.first;
    return tokens[(idx + 1) % tokens.length];
  }

  /// Deterministically assigns a token based on category name hash.
  static String fallbackToken(String name) =>
      tokens[name.hashCode.abs() % tokens.length];
}

// ---------------------------------------------------------------------------
// SpendItem
// ---------------------------------------------------------------------------

class SpendItem {
  SpendItem({
    String? id,
    required this.title,
    required this.amountMinor,
    this.category,
    this.isDemo = false,
  }) : id = id ?? _generateId();

  final String id;
  final String title;
  final int amountMinor;
  final String? category;
  final bool isDemo;

  static String _generateId() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36) +
      (DateTime.now().hashCode & 0xFFFF).toRadixString(36);

  SpendItem copyWith({
    String? title,
    int? amountMinor,
    String? category,
    bool? isDemo,
  }) =>
      SpendItem(
        id: id,
        title: title ?? this.title,
        amountMinor: amountMinor ?? this.amountMinor,
        category: category ?? this.category,
        isDemo: isDemo ?? this.isDemo,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amountMinor': amountMinor,
        'category': category,
        'isDemo': isDemo,
      };

  factory SpendItem.fromJson(Map<String, dynamic> json) => SpendItem(
        id: json['id'] as String?,
        title: json['title'] as String,
        amountMinor: json['amountMinor'] as int,
        category: json['category'] as String?,
        isDemo: json['isDemo'] as bool? ?? false,
      );
}

// ---------------------------------------------------------------------------
// DayEntry
// ---------------------------------------------------------------------------

class DayEntry {
  DayEntry({
    required this.dayIndex,
    required this.dateIso,
    required this.currencyCode,
    required this.dailyLimitMinor,
    DayStatus? status,
    this.conversionRateUsed,
    List<SpendItem>? items,
  })  : status = status ?? DayStatus.open,
        items = items ?? [];

  final int dayIndex;
  final String dateIso;
  final String currencyCode;
  final int dailyLimitMinor;
  DayStatus status;
  final double? conversionRateUsed;
  final List<SpendItem> items;

  int get totalSpent => items.fold(0, (sum, item) => sum + item.amountMinor);
  int get remainingMinor => dailyLimitMinor - totalSpent;
  int get allowedTotalMinor => (dailyLimitMinor * 1.05).round();

  double get fillRatio =>
      dailyLimitMinor > 0 ? totalSpent / dailyLimitMinor : 0.0;

  bool get isPerfectFill => totalSpent == dailyLimitMinor && status == DayStatus.filled;

  /// The calendar date this entry corresponds to (local timezone).
  DateTime get date => DateTime.parse(dateIso).toLocal();

  DayEntry copyWith({
    DayStatus? status,
    List<SpendItem>? items,
    double? conversionRateUsed,
  }) =>
      DayEntry(
        dayIndex: dayIndex,
        dateIso: dateIso,
        currencyCode: currencyCode,
        dailyLimitMinor: dailyLimitMinor,
        status: status ?? this.status,
        conversionRateUsed: conversionRateUsed ?? this.conversionRateUsed,
        items: items ?? List.of(this.items),
      );

  Map<String, dynamic> toJson() => {
        'dayIndex': dayIndex,
        'dateIso': dateIso,
        'currencyCode': currencyCode,
        'dailyLimitMinor': dailyLimitMinor,
        'status': status.name,
        'conversionRateUsed': conversionRateUsed,
        'items': items.map((item) => item.toJson()).toList(),
      };

  factory DayEntry.fromJson(Map<String, dynamic> json) => DayEntry(
        dayIndex: json['dayIndex'] as int,
        dateIso: json['dateIso'] as String,
        currencyCode: json['currencyCode'] as String,
        dailyLimitMinor: json['dailyLimitMinor'] as int,
        status: _parseStatus(json['status'] as String?),
        conversionRateUsed: (json['conversionRateUsed'] as num?)?.toDouble(),
        items: ((json['items'] as List<dynamic>?) ?? [])
            .map((item) => SpendItem.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

  /// Accepts both "open" (new) and "pending" (old Flutter naming).
  static DayStatus _parseStatus(String? raw) {
    if (raw == null) return DayStatus.open;
    if (raw == 'pending') return DayStatus.open; // backward compat
    return DayStatus.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => DayStatus.open,
    );
  }
}

// ---------------------------------------------------------------------------
// GameSettings
// ---------------------------------------------------------------------------

class GameSettings {
  GameSettings({
    required this.languageCode,
    required this.notificationsEnabled,
    required this.reminderHour,
    required this.reminderMinute,
    required this.maxBehavior,
    required this.onboardingShown,
    Map<String, int>? startAmountMinorByLanguage,
    Map<String, int>? maxAmountMinorByLanguage,
    Map<String, String>? currencyByLanguage,
    Map<String, double>? approxFxTable,
  })  : startAmountMinorByLanguage =
            startAmountMinorByLanguage ?? _defaultStartAmounts,
        maxAmountMinorByLanguage =
            maxAmountMinorByLanguage ?? _defaultMaxAmounts,
        currencyByLanguage = currencyByLanguage ?? _defaultCurrencyByLanguage,
        approxFxTable = approxFxTable ?? _defaultFx;

  final String languageCode;
  final bool notificationsEnabled;
  final int reminderHour;
  final int reminderMinute;
  final MaxBehavior maxBehavior;
  final bool onboardingShown;
  final Map<String, int> startAmountMinorByLanguage;
  final Map<String, int> maxAmountMinorByLanguage;
  final Map<String, String> currencyByLanguage;
  final Map<String, double> approxFxTable;

  static const Map<String, int> _defaultStartAmounts = {
    'en': 500,
    'de': 460,
    'ru': 50000,
  };

  static const Map<String, int> _defaultMaxAmounts = {
    'en': 100000000,
    'de': 92000000,
    'ru': 10000000000,
  };

  static const Map<String, String> _defaultCurrencyByLanguage = {
    'en': 'USD',
    'de': 'EUR',
    'ru': 'RUB',
  };

  static const Map<String, double> _defaultFx = {
    'USD_RUB': 100,
    'RUB_USD': 0.01,
    'USD_EUR': 0.92,
    'EUR_USD': 1.08,
    'EUR_RUB': 108,
    'RUB_EUR': 0.0093,
  };

  factory GameSettings.defaults([String deviceLanguage = 'en']) {
    final lang =
        ['ru', 'de', 'en'].contains(deviceLanguage) ? deviceLanguage : 'en';
    return GameSettings(
      languageCode: lang,
      notificationsEnabled: false,
      reminderHour: 14,
      reminderMinute: 15,
      maxBehavior: MaxBehavior.reset,
      onboardingShown: false,
    );
  }

  GameSettings copyWith({
    String? languageCode,
    bool? notificationsEnabled,
    int? reminderHour,
    int? reminderMinute,
    MaxBehavior? maxBehavior,
    bool? onboardingShown,
    Map<String, int>? startAmountMinorByLanguage,
    Map<String, int>? maxAmountMinorByLanguage,
    Map<String, String>? currencyByLanguage,
    Map<String, double>? approxFxTable,
  }) =>
      GameSettings(
        languageCode: languageCode ?? this.languageCode,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        reminderHour: reminderHour ?? this.reminderHour,
        reminderMinute: reminderMinute ?? this.reminderMinute,
        maxBehavior: maxBehavior ?? this.maxBehavior,
        onboardingShown: onboardingShown ?? this.onboardingShown,
        startAmountMinorByLanguage:
            startAmountMinorByLanguage ?? this.startAmountMinorByLanguage,
        maxAmountMinorByLanguage:
            maxAmountMinorByLanguage ?? this.maxAmountMinorByLanguage,
        currencyByLanguage: currencyByLanguage ?? this.currencyByLanguage,
        approxFxTable: approxFxTable ?? this.approxFxTable,
      );

  Map<String, dynamic> toJson() => {
        'languageCode': languageCode,
        'notificationsEnabled': notificationsEnabled,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'maxBehavior': maxBehavior.name,
        'onboardingShown': onboardingShown,
        'startAmountMinorByLanguage': startAmountMinorByLanguage,
        'maxAmountMinorByLanguage': maxAmountMinorByLanguage,
        'currencyByLanguage': currencyByLanguage,
        'approxFxTable': approxFxTable,
      };

  factory GameSettings.fromJson(Map<String, dynamic> json) {
    Map<String, int> intMap(Object? data) =>
        ((data as Map<String, dynamic>? ?? <String, dynamic>{})
            .map((key, value) => MapEntry(key, (value as num).round())));

    Map<String, double> doubleMap(Object? data) =>
        ((data as Map<String, dynamic>? ?? <String, dynamic>{})
            .map((key, value) => MapEntry(key, (value as num).toDouble())));

    return GameSettings(
      languageCode: json['languageCode'] as String? ?? 'en',
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? false,
      reminderHour: json['reminderHour'] as int? ?? 14,
      reminderMinute: json['reminderMinute'] as int? ?? 15,
      maxBehavior: MaxBehavior.values.firstWhere(
        (item) => item.name == json['maxBehavior'],
        orElse: () => MaxBehavior.reset,
      ),
      onboardingShown: json['onboardingShown'] as bool? ?? false,
      startAmountMinorByLanguage:
          intMap(json['startAmountMinorByLanguage']).isEmpty
              ? null
              : intMap(json['startAmountMinorByLanguage']),
      maxAmountMinorByLanguage: intMap(json['maxAmountMinorByLanguage']).isEmpty
          ? null
          : intMap(json['maxAmountMinorByLanguage']),
      currencyByLanguage:
          ((json['currencyByLanguage'] as Map<String, dynamic>? ??
                  <String, dynamic>{})
              .map((key, value) => MapEntry(key, value as String))),
      approxFxTable: doubleMap(json['approxFxTable']),
    );
  }
}

// ---------------------------------------------------------------------------
// Achievement
// ---------------------------------------------------------------------------

class Achievement {
  Achievement({required this.id, required this.titleKey, this.earnedAtIso});

  final String id;
  final String titleKey;
  String? earnedAtIso;

  bool get isEarned => earnedAtIso != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'titleKey': titleKey,
        'earnedAtIso': earnedAtIso,
      };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
        id: json['id'] as String,
        titleKey: json['titleKey'] as String,
        earnedAtIso: json['earnedAtIso'] as String?,
      );
}

// ---------------------------------------------------------------------------
// JSON helpers
// ---------------------------------------------------------------------------

String encodeEntries(List<DayEntry> entries) =>
    jsonEncode(entries.map((entry) => entry.toJson()).toList());

List<DayEntry> decodeEntries(String raw) {
  final list = (jsonDecode(raw) as List<dynamic>);
  return list
      .map((entry) => DayEntry.fromJson(entry as Map<String, dynamic>))
      .toList();
}

String encodeAchievements(List<Achievement> achievements) =>
    jsonEncode(achievements.map((item) => item.toJson()).toList());

List<Achievement> decodeAchievements(String raw) {
  final list = (jsonDecode(raw) as List<dynamic>);
  return list
      .map((item) => Achievement.fromJson(item as Map<String, dynamic>))
      .toList();
}
