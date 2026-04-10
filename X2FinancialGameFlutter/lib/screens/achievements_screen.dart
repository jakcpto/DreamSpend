import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../widgets/app_scope.dart';
import '../widgets/empty_state_view.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final s = AppStrings.of(context);

    final achievements = store.achievements;

    if (achievements.isEmpty) {
      return EmptyStateView(
        icon: Icons.emoji_events_outlined,
        title: s.t('noAchievements'),
        subtitle: s.t('noAchievementsSubtitle'),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(s.t('achievements'))),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: achievements.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final item = achievements[i];
          final isEarned = item.isEarned;
          final earnedDate = item.earnedAtIso != null
              ? DateFormat.yMMMd(store.settings.languageCode)
                  .format(DateTime.parse(item.earnedAtIso!))
              : null;

          return Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isEarned
                          ? const Color(0xFFE8A020).withOpacity(0.15)
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isEarned
                          ? Icons.emoji_events_rounded
                          : Icons.lock_outline_rounded,
                      color: isEarned
                          ? const Color(0xFFE8A020)
                          : Colors.grey.shade400,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.t('achievement.${item.id}'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isEarned ? Colors.black87 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEarned
                              ? '${s.t('earnedOn')} $earnedDate'
                              : _progressHint(item.id, store.streak, s),
                          style: TextStyle(
                            fontSize: 12,
                            color: isEarned
                                ? Colors.black45
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isEarned)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2EC27E).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Color(0xFF2EC27E),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static String _progressHint(
      String id, int currentStreak, AppStrings s) {
    switch (id) {
      case 'streak3':
        return s.t('streakProgress').replaceAll('{n}', '3').replaceAll(
            '{current}', '$currentStreak');
      case 'streak7':
        return s.t('streakProgress')
            .replaceAll('{n}', '7')
            .replaceAll('{current}', '$currentStreak');
      case 'streak14':
        return s.t('streakProgress')
            .replaceAll('{n}', '14')
            .replaceAll('{current}', '$currentStreak');
      case 'streak30':
        return s.t('streakProgress')
            .replaceAll('{n}', '30')
            .replaceAll('{current}', '$currentStreak');
      default:
        return s.t('inProgress');
    }
  }
}
