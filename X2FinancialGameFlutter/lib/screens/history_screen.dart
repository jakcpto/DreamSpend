import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../models/game_models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scope.dart';
import '../widgets/empty_state_view.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final s = AppStrings.of(context);

    final days = store.days.reversed.toList();

    if (days.isEmpty) {
      return EmptyStateView(
        icon: Icons.history_toggle_off_rounded,
        title: s.t('noDays'),
        subtitle: s.t('noDaysSubtitle'),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(s.t('history'))),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= kTabletBreakpoint;
          if (isTablet) {
            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3.2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: days.length,
              itemBuilder: (ctx, i) => _DayCard(
                day: days[i],
                store: store,
                strings: s,
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: days.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) => _DayCard(
              day: days[i],
              store: store,
              strings: s,
            ),
          );
        },
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.store,
    required this.strings,
  });

  final DayEntry day;
  final dynamic store; // GameStore
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat.yMMMd(store.settings.languageCode)
        .format(day.date);
    final statusColor = _statusColor(day.status);
    final statusLabel = _statusLabel(day.status, strings);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.go('/today/day/${day.dayIndex}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  '${day.dayIndex}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${strings.t('day')} ${day.dayIndex}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      date,
                      style: const TextStyle(
                          color: Colors.black45, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    store.formatMoney(day.dailyLimitMinor, day.currencyCode),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _statusColor(DayStatus status) {
    switch (status) {
      case DayStatus.open:
        return const Color(0xFF4A90D9);
      case DayStatus.filled:
        return const Color(0xFF2EC27E);
      case DayStatus.missed:
        return const Color(0xFFE8A020);
    }
  }

  static String _statusLabel(DayStatus status, AppStrings s) {
    switch (status) {
      case DayStatus.open:
        return s.t('statusOpen');
      case DayStatus.filled:
        return s.t('statusFilled');
      case DayStatus.missed:
        return s.t('statusMissed');
    }
  }
}
