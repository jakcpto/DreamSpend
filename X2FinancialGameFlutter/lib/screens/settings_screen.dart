import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/game_models.dart';
import '../state/game_store.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.store});

  final GameStore store;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(s.t('language'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'en', label: Text('EN')),
            ButtonSegment(value: 'ru', label: Text('RU')),
            ButtonSegment(value: 'de', label: Text('DE')),
          ],
          selected: {store.settings.languageCode},
          onSelectionChanged: (value) => store.switchLanguage(value.first),
        ),
        const SizedBox(height: 24),
        Text(s.t('maxBehavior'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        RadioListTile<MaxBehavior>(
          value: MaxBehavior.reset,
          groupValue: store.settings.maxBehavior,
          onChanged: (value) => store.updateMaxBehavior(value!),
          title: Text(s.t('reset')),
        ),
        RadioListTile<MaxBehavior>(
          value: MaxBehavior.cap,
          groupValue: store.settings.maxBehavior,
          onChanged: (value) => store.updateMaxBehavior(value!),
          title: Text(s.t('cap')),
        ),
      ],
    );
  }
}
