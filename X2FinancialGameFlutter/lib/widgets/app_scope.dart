import 'package:flutter/widgets.dart';

import '../state/game_store.dart';

class AppScope extends InheritedNotifier<GameStore> {
  const AppScope({super.key, required super.notifier, required super.child});

  static GameStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    return scope!.notifier!;
  }
}
