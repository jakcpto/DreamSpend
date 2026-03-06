import 'dart:convert';

enum DayStatus { filled, missed, pending }
enum MaxBehavior { reset, cap }

class SpendItem {
  SpendItem({
    required this.title,
    required this.amountMinor,
    this.category,
  });

  final String title;
  final int amountMinor;
  final String? category;

  Map<String, dynamic> toJson() => {
        'title': title,
        'amountMinor': amountMinor,
        'category': category,
      };

  factory SpendItem.fromJson(Map<String, dynamic> json) => SpendItem(
        title: json['title'] as String,
        amountMinor: json['amountMinor'] as int,
        category: json['category'] as String?,
      );
}

class DayEntry {
  DayEntry({
    required this.dayIndex,
    required this.dateIso,
    required this.currencyCode,
    required this.dailyLimitMinor,
    this.status = DayStatus.pending,
    this.conversionRateUsed,
    List<SpendItem>? items,
  }) : items = items ?? [];

  final int dayIndex;
  final String dateIso;
  final String currencyCode;
  final int dailyLimitMinor;
  DayStatus status;
  final double? conversionRateUsed;
  final List<SpendItem> items;

  int get totalSpent => items.fold(0, (sum, item) => sum + item.amountMinor);

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
        status: DayStatus.values.firstWhere(
          (status) => status.name == json['status'],
          orElse: () => DayStatus.pending,
        ),
        conversionRateUsed: (json['conversionRateUsed'] as num?)?.toDouble(),
        items: ((json['items'] as List<dynamic>?) ?? [])
            .map((item) => SpendItem.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}

class GameSettings {
  GameSettings({
    required this.languageCode,
    required this.notificationsEnabled,
    required this.reminderHour,
    required this.reminderMinute,
    required this.maxBehavior,
    Map<String, int>? startAmountMinorByLanguage,
    Map<String, int>? maxAmountMinorByLanguage,
    Map<String, String>? currencyByLanguage,
    Map<String, double>? approxFxTable,
  })  : startAmountMinorByLanguage = startAmountMinorByLanguage ?? _defaultStartAmounts,
        maxAmountMinorByLanguage = maxAmountMinorByLanguage ?? _defaultMaxAmounts,
        currencyByLanguage = currencyByLanguage ?? _defaultCurrencyByLanguage,
        approxFxTable = approxFxTable ?? _defaultFx;

  final String languageCode;
  final bool notificationsEnabled;
  final int reminderHour;
  final int reminderMinute;
  final MaxBehavior maxBehavior;
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
    final lang = ['ru', 'de', 'en'].contains(deviceLanguage) ? deviceLanguage : 'en';
    return GameSettings(
      languageCode: lang,
      notificationsEnabled: false,
      reminderHour: 14,
      reminderMinute: 15,
      maxBehavior: MaxBehavior.reset,
    );
  }

  GameSettings copyWith({
    String? languageCode,
    bool? notificationsEnabled,
    int? reminderHour,
    int? reminderMinute,
    MaxBehavior? maxBehavior,
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
        startAmountMinorByLanguage:
            startAmountMinorByLanguage ?? this.startAmountMinorByLanguage,
        maxAmountMinorByLanguage: maxAmountMinorByLanguage ?? this.maxAmountMinorByLanguage,
        currencyByLanguage: currencyByLanguage ?? this.currencyByLanguage,
        approxFxTable: approxFxTable ?? this.approxFxTable,
      );

  Map<String, dynamic> toJson() => {
        'languageCode': languageCode,
        'notificationsEnabled': notificationsEnabled,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'maxBehavior': maxBehavior.name,
        'startAmountMinorByLanguage': startAmountMinorByLanguage,
        'maxAmountMinorByLanguage': maxAmountMinorByLanguage,
        'currencyByLanguage': currencyByLanguage,
        'approxFxTable': approxFxTable,
      };

  factory GameSettings.fromJson(Map<String, dynamic> json) {
    Map<String, int> _intMap(Object? data) => ((data as Map<String, dynamic>? ?? <String, dynamic>{})
          .map((key, value) => MapEntry(key, (value as num).round())));

    Map<String, double> _doubleMap(Object? data) =>
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
      startAmountMinorByLanguage: _intMap(json['startAmountMinorByLanguage']),
      maxAmountMinorByLanguage: _intMap(json['maxAmountMinorByLanguage']),
      currencyByLanguage: ((json['currencyByLanguage'] as Map<String, dynamic>? ?? <String, dynamic>{})
          .map((key, value) => MapEntry(key, value as String))),
      approxFxTable: _doubleMap(json['approxFxTable']),
    );
  }
}

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

String encodeEntries(List<DayEntry> entries) =>
    jsonEncode(entries.map((entry) => entry.toJson()).toList());

List<DayEntry> decodeEntries(String raw) {
  final list = (jsonDecode(raw) as List<dynamic>);
  return list.map((entry) => DayEntry.fromJson(entry as Map<String, dynamic>)).toList();
}

String encodeAchievements(List<Achievement> achievements) =>
    jsonEncode(achievements.map((item) => item.toJson()).toList());

List<Achievement> decodeAchievements(String raw) {
  final list = (jsonDecode(raw) as List<dynamic>);
  return list.map((item) => Achievement.fromJson(item as Map<String, dynamic>)).toList();
}
