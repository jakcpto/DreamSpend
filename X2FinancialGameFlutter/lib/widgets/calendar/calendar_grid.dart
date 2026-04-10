import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/game_models.dart';
import 'day_tile.dart';

class _MonthSection {
  _MonthSection({required this.label, required this.days});
  final String label;
  final List<DayEntry> days;
}

/// Scrollable calendar grid grouped by month.
/// Scrolls to the last tile on mount.
class CalendarGrid extends StatefulWidget {
  const CalendarGrid({
    super.key,
    required this.days,
    required this.selectedDayIndex,
    required this.locale,
    required this.formatMoney,
    required this.todayDayIndex,
    required this.onSelected,
    required this.onEditRequested,
    this.liquidEffect = true,
  });

  final List<DayEntry> days;
  final int? selectedDayIndex;
  final String locale;
  final String Function(int minor, String currency) formatMoney;
  final int todayDayIndex;
  final void Function(int dayIndex) onSelected;
  final void Function(int dayIndex) onEditRequested;
  final bool liquidEffect;

  @override
  State<CalendarGrid> createState() => _CalendarGridState();
}

class _CalendarGridState extends State<CalendarGrid> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  @override
  void didUpdateWidget(CalendarGrid old) {
    super.didUpdateWidget(old);
    if (old.days.length != widget.days.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    }
  }

  void _scrollToEnd() {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  List<_MonthSection> _buildSections() {
    final sections = <_MonthSection>[];
    _MonthSection? current;
    String? currentKey;

    for (final day in widget.days) {
      final date = day.date;
      final key = '${date.year}-${date.month}';
      if (key != currentKey) {
        final label = DateFormat('LLLL y', widget.locale).format(date);
        current = _MonthSection(
          label: label[0].toUpperCase() + label.substring(1),
          days: [],
        );
        sections.add(current);
        currentKey = key;
      }
      current!.days.add(day);
    }
    return sections;
  }

  @override
  Widget build(BuildContext context) {
    final sections = _buildSections();
    if (sections.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      controller: _scroll,
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final section in sections) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 6, top: 4),
                  child: Text(
                    section.label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                          letterSpacing: 0.4,
                        ),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final day in section.days)
                      DayTile(
                        key: ValueKey(day.dayIndex),
                        day: day,
                        isSelected: day.dayIndex == widget.selectedDayIndex,
                        isToday: day.dayIndex == widget.todayDayIndex,
                        formatMoney: widget.formatMoney,
                        onSelected: () => widget.onSelected(day.dayIndex),
                        onEditRequested: () =>
                            widget.onEditRequested(day.dayIndex),
                        liquidEffect: widget.liquidEffect,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
