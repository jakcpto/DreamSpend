import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../state/game_store.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.store});

  final GameStore store;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    if (store.days.isEmpty) {
      return Center(child: Text(s.t('noDays')));
    }

    return ListView.builder(
      itemCount: store.days.length,
      itemBuilder: (context, index) {
        final day = store.days[index];
        final date = DateFormat.yMMMd(store.settings.languageCode)
            .format(DateTime.parse(day.dateIso));
        return ListTile(
          leading: CircleAvatar(child: Text('${day.dayIndex}')),
          title: Text('${s.t('day')} ${day.dayIndex} · $date'),
          subtitle: Text(store.formatMoney(day.dailyLimitMinor, day.currencyCode)),
          trailing: Text(day.status.name),
        );
      },
    );
  }
}
