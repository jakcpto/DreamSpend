import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../state/game_store.dart';
import 'day_spends_screen.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key, required this.store});

  final GameStore store;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final today = store.today;
    final max = store.settings.maxAmountMinorByLanguage[store.settings.languageCode]!;
    final progress = today.dailyLimitMinor / max;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${s.t('day')} ${today.dayIndex}', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('${s.t('limit')}: ${store.formatMoney(today.dailyLimitMinor, today.currencyCode)}'),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress.clamp(0, 1)),
          const SizedBox(height: 24),
          Text('${s.t('streak')}: ${store.streak}'),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => DaySpendsScreen(store: store)),
            ),
            child: Text(s.t('fillSpends')),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: store.markMissedDay,
            child: const Text('Skip day'),
          ),
        ],
      ),
    );
  }
}
