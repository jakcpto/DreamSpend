import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.child});

  final Widget child;

  static const _tabs = ['/today', '/history', '/achievements', '/settings'];

  static const _icons = [
    Icons.today_rounded,
    Icons.history_rounded,
    Icons.workspace_premium_rounded,
    Icons.settings_rounded,
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final currentIndex = _currentIndex(context);

    final labels = [
      s.t('today'),
      s.t('history'),
      s.t('achievements'),
      s.t('settings'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= kTabletBreakpoint;
        final isWide = constraints.maxWidth >= kTabletExtendedBreakpoint;

        if (isTablet) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Row(
              children: [
                NavigationRail(
                  extended: isWide,
                  selectedIndex: currentIndex,
                  backgroundColor: Colors.white.withOpacity(0.65),
                  indicatorColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.15),
                  onDestinationSelected: (i) => context.go(_tabs[i]),
                  destinations: [
                    for (int i = 0; i < _tabs.length; i++)
                      NavigationRailDestination(
                        icon: Icon(_icons[i]),
                        label: Text(labels[i]),
                      ),
                  ],
                ),
                const VerticalDivider(thickness: 0.5, width: 1),
                Expanded(child: child),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: child,
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              border: Border(
                top: BorderSide(color: Colors.grey.shade200, width: 0.5),
              ),
            ),
            child: NavigationBar(
              selectedIndex: currentIndex,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              onDestinationSelected: (i) => context.go(_tabs[i]),
              destinations: [
                for (int i = 0; i < _tabs.length; i++)
                  NavigationDestination(
                    icon: Icon(_icons[i]),
                    label: labels[i],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
