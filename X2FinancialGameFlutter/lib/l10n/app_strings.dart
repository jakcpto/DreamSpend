import 'package:flutter/widgets.dart';

class AppStrings {
  AppStrings(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('ru'), Locale('de')];

  static const Map<String, Map<String, String>> _data = {
    'en': {
      // Core navigation
      'appTitle': 'DreamSpend',
      'today': 'Today',
      'day': 'Day',
      'history': 'History',
      'achievements': 'Achievements',
      'settings': 'Settings',
      // Today / detail panel
      'fillSpends': 'Fill spends',
      'selectDay': 'Select a day',
      'noItems': 'No items yet',
      'longPressHint': 'Long press tile to add',
      'statusOpen': 'Open',
      'statusFilled': 'Filled',
      'statusMissed': 'Missed',
      'status': 'Status',
      // Spend editor
      'limit': 'Limit',
      'total': 'Spent',
      'remaining': 'Remaining',
      'plus5Hint': '+5% allowed',
      'title': 'Title',
      'amount': 'Amount',
      'addItem': 'Add item',
      'updateItem': 'Update',
      'saveDay': 'Save day',
      'addCategory': 'Add category',
      // History
      'noDays': 'No days yet',
      'noDaysSubtitle': 'Start filling your daily budget to see history',
      // Achievements
      'noAchievements': 'No achievements',
      'noAchievementsSubtitle': 'Keep playing to earn achievements',
      'earnedOn': 'Earned on',
      'inProgress': 'In progress',
      'streakProgress': 'Streak {n} — current: {current}',
      'achievement.streak3': '3-day streak',
      'achievement.streak7': '7-day streak',
      'achievement.streak14': '14-day streak',
      'achievement.streak30': '30-day streak',
      'achievement.perfect': 'Perfect fill',
      'achievement.maximum': 'Reached maximum',
      // Settings
      'language': 'Language',
      'limits': 'Daily limits',
      'startAmount': 'Start amount',
      'maxAmount': 'Max amount',
      'save': 'Save',
      'maxBehavior': 'At maximum',
      'reset': 'Reset & restart',
      'cap': 'Ceiling mode',
      'maxBehaviorResetHint': 'Returns to the start amount after reaching maximum.',
      'maxBehaviorCapHint': 'Stays at the maximum amount forever.',
      'fxRate': 'Exchange rate',
      'manualRate': 'e.g. 90.0',
      'update': 'Update',
      'fetchLiveRate': 'Fetch live rate',
      'notifications': 'Notifications',
      'enableNotifications': 'Daily reminder',
      'reminderTime': 'Reminder time',
      'onboarding': 'Tutorial',
      'replayOnboarding': 'Replay tutorial',
      'dangerZone': 'Danger zone',
      'resetAll': 'Reset all progress',
      'resetTitle': 'Reset all?',
      'resetConfirm': 'This will delete all days, achievements, and progress. This cannot be undone.',
      'cancel': 'Cancel',
      'streak': 'Streak',
      // Onboarding
      'onboarding.title.1': 'Track daily budgets',
      'onboarding.body.1': 'Each day you spend within your budget, the next day\'s budget doubles.',
      'onboarding.title.2': 'Add spending items',
      'onboarding.body.2': 'Record every expense with a title, amount, and category.',
      'onboarding.title.3': 'Earn achievements',
      'onboarding.body.3': 'Build streaks and reach the maximum budget to unlock achievements.',
      'onboarding.footer': 'No real money involved. This is a savings habit game.',
      'onboarding.next': 'Next',
      'onboarding.startDemo': 'Start',
      'onboarding.skip': 'Skip',
      // Celebration
      'celebration.title': 'Maximum reached!',
      'celebration.subtitle': 'Virtual prize awarded 🎉',
      'celebration.restart': 'Restart',
      'celebration.close': 'Close',
    },
    'ru': {
      // Core navigation
      'appTitle': 'DreamSpend',
      'today': 'Сегодня',
      'day': 'День',
      'history': 'История',
      'achievements': 'Ачивки',
      'settings': 'Настройки',
      // Today / detail panel
      'fillSpends': 'Добавить траты',
      'selectDay': 'Выберите день',
      'noItems': 'Трат пока нет',
      'longPressHint': 'Долгое нажатие на тайл для добавления',
      'statusOpen': 'Открыт',
      'statusFilled': 'Заполнен',
      'statusMissed': 'Пропущен',
      'status': 'Статус',
      // Spend editor
      'limit': 'Лимит',
      'total': 'Потрачено',
      'remaining': 'Осталось',
      'plus5Hint': '+5% допустимо',
      'title': 'Название',
      'amount': 'Сумма',
      'addItem': 'Добавить',
      'updateItem': 'Обновить',
      'saveDay': 'Сохранить день',
      'addCategory': 'Добавить категорию',
      // History
      'noDays': 'Дней пока нет',
      'noDaysSubtitle': 'Начните заполнять дневной бюджет, чтобы видеть историю',
      // Achievements
      'noAchievements': 'Нет достижений',
      'noAchievementsSubtitle': 'Продолжайте играть, чтобы разблокировать достижения',
      'earnedOn': 'Получено',
      'inProgress': 'В процессе',
      'streakProgress': 'Стрик {n} — сейчас: {current}',
      'achievement.streak3': 'Стрик 3 дня',
      'achievement.streak7': 'Стрик 7 дней',
      'achievement.streak14': 'Стрик 14 дней',
      'achievement.streak30': 'Стрик 30 дней',
      'achievement.perfect': 'Идеальное заполнение',
      'achievement.maximum': 'Достигнут максимум',
      // Settings
      'language': 'Язык',
      'limits': 'Дневные лимиты',
      'startAmount': 'Начальная сумма',
      'maxAmount': 'Максимум',
      'save': 'Сохранить',
      'maxBehavior': 'При максимуме',
      'reset': 'Сброс и рестарт',
      'cap': 'Потолок',
      'maxBehaviorResetHint': 'После достижения максимума сбрасывается к начальной сумме.',
      'maxBehaviorCapHint': 'Остаётся на максимальной сумме.',
      'fxRate': 'Курс валют',
      'manualRate': 'напр. 90.0',
      'update': 'Обновить',
      'fetchLiveRate': 'Получить курс',
      'notifications': 'Уведомления',
      'enableNotifications': 'Напоминание',
      'reminderTime': 'Время напоминания',
      'onboarding': 'Обучение',
      'replayOnboarding': 'Пройти обучение снова',
      'dangerZone': 'Опасная зона',
      'resetAll': 'Сбросить весь прогресс',
      'resetTitle': 'Сбросить всё?',
      'resetConfirm': 'Это удалит все дни, достижения и прогресс. Это нельзя отменить.',
      'cancel': 'Отмена',
      'streak': 'Стрик',
      // Onboarding
      'onboarding.title.1': 'Отслеживайте бюджеты',
      'onboarding.body.1': 'Каждый день, когда вы укладываетесь в бюджет, бюджет следующего дня удваивается.',
      'onboarding.title.2': 'Добавляйте траты',
      'onboarding.body.2': 'Записывайте каждую трату с названием, суммой и категорией.',
      'onboarding.title.3': 'Зарабатывайте достижения',
      'onboarding.body.3': 'Удерживайте стрик и достигайте максимального бюджета, чтобы разблокировать достижения.',
      'onboarding.footer': 'Настоящие деньги не используются. Это игра для формирования привычки к сбережениям.',
      'onboarding.next': 'Далее',
      'onboarding.startDemo': 'Начать',
      'onboarding.skip': 'Пропустить',
      // Celebration
      'celebration.title': 'Максимум достигнут!',
      'celebration.subtitle': 'Виртуальный приз вручён 🎉',
      'celebration.restart': 'Начать заново',
      'celebration.close': 'Закрыть',
    },
    'de': {
      // Core navigation
      'appTitle': 'DreamSpend',
      'today': 'Heute',
      'day': 'Tag',
      'history': 'Verlauf',
      'achievements': 'Erfolge',
      'settings': 'Einstellungen',
      // Today / detail panel
      'fillSpends': 'Ausgaben eintragen',
      'selectDay': 'Tag auswählen',
      'noItems': 'Noch keine Ausgaben',
      'longPressHint': 'Lang drücken um hinzuzufügen',
      'statusOpen': 'Offen',
      'statusFilled': 'Gefüllt',
      'statusMissed': 'Verpasst',
      'status': 'Status',
      // Spend editor
      'limit': 'Limit',
      'total': 'Ausgegeben',
      'remaining': 'Verbleibend',
      'plus5Hint': '+5% erlaubt',
      'title': 'Titel',
      'amount': 'Betrag',
      'addItem': 'Hinzufügen',
      'updateItem': 'Aktualisieren',
      'saveDay': 'Tag speichern',
      'addCategory': 'Kategorie hinzufügen',
      // History
      'noDays': 'Noch keine Tage',
      'noDaysSubtitle': 'Beginne, dein Tagesbudget auszufüllen, um den Verlauf zu sehen',
      // Achievements
      'noAchievements': 'Keine Erfolge',
      'noAchievementsSubtitle': 'Spiele weiter, um Erfolge zu verdienen',
      'earnedOn': 'Erhalten am',
      'inProgress': 'In Bearbeitung',
      'streakProgress': 'Serie {n} — aktuell: {current}',
      'achievement.streak3': '3-Tage-Serie',
      'achievement.streak7': '7-Tage-Serie',
      'achievement.streak14': '14-Tage-Serie',
      'achievement.streak30': '30-Tage-Serie',
      'achievement.perfect': 'Perfektes Ausfüllen',
      'achievement.maximum': 'Maximum erreicht',
      // Settings
      'language': 'Sprache',
      'limits': 'Tageslimits',
      'startAmount': 'Startbetrag',
      'maxAmount': 'Maximum',
      'save': 'Speichern',
      'maxBehavior': 'Bei Maximum',
      'reset': 'Zurücksetzen und neu',
      'cap': 'Deckel-Modus',
      'maxBehaviorResetHint': 'Nach Erreichen des Maximums wird auf den Startbetrag zurückgesetzt.',
      'maxBehaviorCapHint': 'Bleibt dauerhaft beim Maximalbetrag.',
      'fxRate': 'Wechselkurs',
      'manualRate': 'z.B. 90,0',
      'update': 'Aktualisieren',
      'fetchLiveRate': 'Kurs abrufen',
      'notifications': 'Benachrichtigungen',
      'enableNotifications': 'Tägliche Erinnerung',
      'reminderTime': 'Erinnerungszeit',
      'onboarding': 'Tutorial',
      'replayOnboarding': 'Tutorial wiederholen',
      'dangerZone': 'Gefahrenzone',
      'resetAll': 'Fortschritt zurücksetzen',
      'resetTitle': 'Alles zurücksetzen?',
      'resetConfirm': 'Dies löscht alle Tage, Erfolge und Fortschritte. Dies kann nicht rückgängig gemacht werden.',
      'cancel': 'Abbrechen',
      'streak': 'Serie',
      // Onboarding
      'onboarding.title.1': 'Tagesbudgets verfolgen',
      'onboarding.body.1': 'Wenn du jeden Tag im Budget bleibst, verdoppelt sich das Budget des nächsten Tages.',
      'onboarding.title.2': 'Ausgaben hinzufügen',
      'onboarding.body.2': 'Erfasse jede Ausgabe mit Titel, Betrag und Kategorie.',
      'onboarding.title.3': 'Erfolge verdienen',
      'onboarding.body.3': 'Baue Serien auf und erreiche das Maximalbudget, um Erfolge zu entsperren.',
      'onboarding.footer': 'Kein echtes Geld involviert. Dies ist ein Spargewohnheits-Spiel.',
      'onboarding.next': 'Weiter',
      'onboarding.startDemo': 'Starten',
      'onboarding.skip': 'Überspringen',
      // Celebration
      'celebration.title': 'Maximum erreicht!',
      'celebration.subtitle': 'Virtueller Preis vergeben 🎉',
      'celebration.restart': 'Neu starten',
      'celebration.close': 'Schließen',
    },
  };

  String t(String key) {
    final lang = _data[locale.languageCode] ?? _data['en']!;
    return lang[key] ?? _data['en']![key] ?? key;
  }

  static AppStrings of(BuildContext context) {
    final inherited = context.dependOnInheritedWidgetOfExactType<_StringsProvider>();
    return inherited!.strings;
  }
}

class StringsScope extends StatelessWidget {
  const StringsScope({super.key, required this.locale, required this.child});

  final Locale locale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _StringsProvider(strings: AppStrings(locale), child: child);
  }
}

class _StringsProvider extends InheritedWidget {
  const _StringsProvider({required this.strings, required super.child});

  final AppStrings strings;

  @override
  bool updateShouldNotify(_StringsProvider oldWidget) =>
      oldWidget.strings.locale != strings.locale;
}
