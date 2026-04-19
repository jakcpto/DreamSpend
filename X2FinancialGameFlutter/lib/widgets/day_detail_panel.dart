import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/game_models.dart';
import '../state/game_store.dart';
import 'empty_state_view.dart';
import 'panel_card.dart';

class DayDetailPanel extends StatelessWidget {
  const DayDetailPanel({
    super.key,
    required this.day,
    required this.store,
    required this.strings,
    required this.onEditRequested,
  });

  final DayEntry? day;
  final GameStore store;
  final Map<String, String> strings;
  final VoidCallback onEditRequested;

  @override
  Widget build(BuildContext context) {
    final d = day;
    if (d == null) {
      return EmptyStateView(
        icon: Icons.touch_app_rounded,
        title: strings['selectDay'] ?? 'Select a day',
      );
    }

    final spent = store.formatMoney(d.totalSpent, d.currencyCode);
    final remaining = store.formatMoney(d.remainingMinor.abs(), d.currencyCode);
    final isOver = d.remainingMinor < 0;

    final dateStr = DateFormat(
      'EEEE, d MMMM y',
      store.settings.languageCode,
    ).format(d.date);

    return PanelCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${strings['day'] ?? 'Day'} ${d.dayIndex}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black45,
                      ),
                ),
              ],
            ),
          ),

          // Stat cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatCard(
                  label: strings['total'] ?? 'Spent',
                  value: spent,
                  color: const Color(0xFF4A90D9),
                ),
                _StatCard(
                  label: strings['remaining'] ?? 'Remaining',
                  value: isOver ? '−$remaining' : remaining,
                  color: isOver ? const Color(0xFFD94040) : const Color(0xFF2EC27E),
                ),
                _StatCard(
                  label: strings['status'] ?? 'Status',
                  value: _statusLabel(d.status, strings),
                  color: _statusColor(d.status),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, indent: 16, endIndent: 16),

          // Spend items list
          Expanded(
            child: d.items.isEmpty
                ? EmptyStateView(
                    icon: Icons.receipt_long_outlined,
                    title: strings['noItems'] ?? 'No items yet',
                    subtitle: strings['longPressHint'] ?? 'Long press tile to add',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: d.items.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 56),
                    itemBuilder: (context, i) {
                      final item = d.items[i];
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: item.category != null
                              ? CategoryPalette.color(
                                  store.colorTokenForCategory(item.category!),
                                ).withOpacity(0.18)
                              : Colors.grey.shade100,
                          child: Text(
                            item.title.isNotEmpty
                                ? item.title[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(item.title,
                            style: const TextStyle(fontSize: 14)),
                        subtitle: item.category != null
                            ? Text(item.category!,
                                style: const TextStyle(fontSize: 11))
                            : null,
                        trailing: Text(
                          store.formatMoney(
                              item.amountMinor, d.currencyCode),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      );
                    },
                  ),
          ),

          // Edit button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: d.status != DayStatus.missed ? onEditRequested : null,
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: Text(strings['fillSpends'] ?? 'Fill spends'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _statusLabel(DayStatus status, Map<String, String> strings) {
    switch (status) {
      case DayStatus.open:
        return strings['statusOpen'] ?? 'Open';
      case DayStatus.filled:
        return strings['statusFilled'] ?? 'Filled';
      case DayStatus.missed:
        return strings['statusMissed'] ?? 'Missed';
    }
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
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 90),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.85),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
