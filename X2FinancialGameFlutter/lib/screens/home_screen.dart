import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../widgets/app_scope.dart';
import 'achievements_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'today_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final store = AppScope.of(context);

    final pages = [
      TodayScreen(store: store),
      HistoryScreen(store: store),
      AchievementsScreen(store: store),
      SettingsScreen(store: store),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('appTitle'))),
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (value) => setState(() => _index = value),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.today), label: strings.t('today')),
          BottomNavigationBarItem(icon: const Icon(Icons.history), label: strings.t('history')),
          BottomNavigationBarItem(
            icon: const Icon(Icons.workspace_premium),
            label: strings.t('achievements'),
          ),
          BottomNavigationBarItem(icon: const Icon(Icons.settings), label: strings.t('settings')),
        ],
      ),
    );
  }
}
