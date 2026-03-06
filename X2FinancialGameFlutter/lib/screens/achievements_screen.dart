import 'package:flutter/material.dart';

import '../state/game_store.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key, required this.store});

  final GameStore store;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: store.achievements.length,
      itemBuilder: (context, index) {
        final item = store.achievements[index];
        return ListTile(
          leading: Icon(item.isEarned ? Icons.emoji_events : Icons.lock_outline),
          title: Text(item.titleKey),
          subtitle: Text(item.earnedAtIso ?? 'In progress'),
        );
      },
    );
  }
}
