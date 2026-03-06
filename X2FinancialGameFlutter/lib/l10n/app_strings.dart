import 'package:flutter/widgets.dart';

class AppStrings {
  AppStrings(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('ru'), Locale('de')];

  static const Map<String, Map<String, String>> _data = {
    'en': {
      'appTitle': 'X2 Financial Game',
      'today': 'Today',
      'day': 'Day',
      'fillSpends': 'Fill spends',
      'history': 'History',
      'achievements': 'Achievements',
      'settings': 'Settings',
      'limit': 'Limit',
      'total': 'Total',
      'remaining': 'Remaining',
      'saveDay': 'Save day',
      'language': 'Language',
      'maxBehavior': 'Max behavior',
      'reset': 'Reset and start over',
      'cap': 'Ceiling mode',
      'streak': 'Streak',
      'noDays': 'No days yet',
      'addItem': 'Add item',
      'title': 'Title',
      'amount': 'Amount',
    },
    'ru': {
      'appTitle': 'Х2 Financial Game',
      'today': 'Сегодня',
      'day': 'День',
      'fillSpends': 'Заполнить траты',
      'history': 'История',
      'achievements': 'Ачивки',
      'settings': 'Настройки',
      'limit': 'Лимит',
      'total': 'Итого',
      'remaining': 'Осталось',
      'saveDay': 'Сохранить день',
      'language': 'Язык',
      'maxBehavior': 'Поведение на максимуме',
      'reset': 'Сброс и заново',
      'cap': 'Потолок',
      'streak': 'Стрик',
      'noDays': 'Дней пока нет',
      'addItem': 'Добавить трату',
      'title': 'Название',
      'amount': 'Сумма',
    },
    'de': {
      'appTitle': 'X2 Financial Game',
      'today': 'Heute',
      'day': 'Tag',
      'fillSpends': 'Ausgaben eintragen',
      'history': 'Verlauf',
      'achievements': 'Erfolge',
      'settings': 'Einstellungen',
      'limit': 'Limit',
      'total': 'Gesamt',
      'remaining': 'Verbleibend',
      'saveDay': 'Tag speichern',
      'language': 'Sprache',
      'maxBehavior': 'Verhalten am Maximum',
      'reset': 'Zurücksetzen und neu',
      'cap': 'Deckel-Modus',
      'streak': 'Serie',
      'noDays': 'Noch keine Tage',
      'addItem': 'Posten hinzufügen',
      'title': 'Titel',
      'amount': 'Betrag',
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
  bool updateShouldNotify(_StringsProvider oldWidget) => oldWidget.strings.locale != strings.locale;
}
