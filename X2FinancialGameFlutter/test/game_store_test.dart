import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:x2_financial_game/models/game_models.dart';
import 'package:x2_financial_game/services/persistence_service.dart';
import 'package:x2_financial_game/state/game_store.dart';

class FakePersistence extends PersistenceService {
  GameSettings? settings;
  List<DayEntry> days = [];
  List<Achievement> achievements = [];
  int streak = 0;
  int misses = 0;

  @override
  Future<GameSettings?> loadSettings() async => settings;

  @override
  Future<List<DayEntry>> loadDays() async => days;

  @override
  Future<List<Achievement>> loadAchievements() async => achievements;

  @override
  Future<(int streak, int misses)> loadProgressMeta() async => (streak, misses);

  @override
  Future<void> saveSettings(GameSettings value) async => settings = value;

  @override
  Future<void> saveDays(List<DayEntry> value) async => days = value;

  @override
  Future<void> saveAchievements(List<Achievement> value) async => achievements = value;

  @override
  Future<void> saveProgressMeta({required int streak, required int misses}) async {
    this.streak = streak;
    this.misses = misses;
  }
}

void main() {
  test('doubles daily limit until max cap', () async {
    final persistence = FakePersistence();
    final store = GameStore(persistence: persistence);
    await store.init(const Locale('en'));

    final start = store.today.dailyLimitMinor;
    store.addSpendItem(title: 'a', amountMinor: 100);
    store.saveToday();

    expect(store.today.dailyLimitMinor, start * 2);
  });

  test('converts pending day when language switches', () async {
    final persistence = FakePersistence();
    final store = GameStore(persistence: persistence);
    await store.init(const Locale('en'));

    final before = store.today.dailyLimitMinor;
    store.switchLanguage('ru');

    expect(store.today.currencyCode, 'RUB');
    expect(store.today.dailyLimitMinor, (before * 100).round());
  });

  test('resets streak after two missed days', () async {
    final persistence = FakePersistence();
    final store = GameStore(persistence: persistence);
    await store.init(const Locale('en'));

    store.addSpendItem(title: 'a', amountMinor: 100);
    store.saveToday();
    expect(store.streak, 1);

    store.markMissedDay();
    store.markMissedDay();

    expect(store.streak, 0);
  });
}
