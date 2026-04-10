import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_strings.dart';
import '../models/game_models.dart';
import '../state/game_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scope.dart';
import '../widgets/calendar/calendar_grid.dart';
import '../widgets/day_detail_panel.dart';
import '../widgets/panel_card.dart';
import 'celebration_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  int? _selectedDayIndex;
  bool _celebrationShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = AppScope.of(context);
      setState(() {
        _selectedDayIndex =
            store.todayEntry?.dayIndex ?? store.today.dayIndex;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkCelebration();
  }

  void _checkCelebration() {
    final store = AppScope.of(context);
    if (store.showCelebration && !_celebrationShown) {
      _celebrationShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showGeneralDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.transparent,
          pageBuilder: (ctx, _, __) => AppScope(
            notifier: store,
            child: StringsScope(
              locale: Locale(store.settings.languageCode),
              child: const CelebrationScreen(),
            ),
          ),
        ).then((_) => _celebrationShown = false);
      });
    }
  }

  void _openSpendEditor(int dayIndex) {
    context.go('/today/day/$dayIndex');
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final strings = AppStrings.of(context);

    _checkCelebration();

    _selectedDayIndex ??= store.days.isNotEmpty ? store.days.last.dayIndex : null;

    final selectedDay = (store.days.isEmpty || _selectedDayIndex == null)
        ? null
        : store.days.firstWhere(
            (d) => d.dayIndex == _selectedDayIndex,
            orElse: () => store.today,
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= kTabletBreakpoint;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: isTablet
                ? _tabletLayout(context, store, strings, selectedDay)
                : _phoneLayout(context, store, strings, selectedDay),
          ),
        );
      },
    );
  }

  Widget _calendarPanel(BuildContext context, GameStore store, AppStrings s) {
    return PanelCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  s.t('today'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (store.streak > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8A020).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFE8A020).withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 13)),
                        const SizedBox(width: 4),
                        Text(
                          '${store.streak}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE8A020),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: store.days.isEmpty
                ? const SizedBox()
                : CalendarGrid(
                    days: store.days,
                    selectedDayIndex: _selectedDayIndex,
                    locale: store.settings.languageCode,
                    formatMoney: store.formatMoney,
                    todayDayIndex: store.today.dayIndex,
                    onSelected: (idx) =>
                        setState(() => _selectedDayIndex = idx),
                    onEditRequested: _openSpendEditor,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _detailPanel(
    BuildContext context,
    GameStore store,
    AppStrings s,
    DayEntry? selectedDay,
  ) {
    return DayDetailPanel(
      day: selectedDay,
      store: store,
      strings: {
        'day': s.t('day'),
        'total': s.t('total'),
        'remaining': s.t('remaining'),
        'fillSpends': s.t('fillSpends'),
        'selectDay': s.t('selectDay'),
        'noItems': s.t('noItems'),
        'longPressHint': s.t('longPressHint'),
        'statusOpen': s.t('statusOpen'),
        'statusFilled': s.t('statusFilled'),
        'statusMissed': s.t('statusMissed'),
        'status': s.t('status'),
      },
      onEditRequested: () =>
          _openSpendEditor(selectedDay?.dayIndex ?? store.today.dayIndex),
    );
  }

  Widget _phoneLayout(
    BuildContext context,
    GameStore store,
    AppStrings s,
    DayEntry? selectedDay,
  ) {
    return Column(
      children: [
        SizedBox(
          height: 280,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: _calendarPanel(context, store, s),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: _detailPanel(context, store, s, selectedDay),
          ),
        ),
      ],
    );
  }

  Widget _tabletLayout(
    BuildContext context,
    GameStore store,
    AppStrings s,
    DayEntry? selectedDay,
  ) {
    return Row(
      children: [
        Flexible(
          flex: 44,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: _calendarPanel(context, store, s),
          ),
        ),
        Flexible(
          flex: 56,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
            child: _detailPanel(context, store, s, selectedDay),
          ),
        ),
      ],
    );
  }
}
