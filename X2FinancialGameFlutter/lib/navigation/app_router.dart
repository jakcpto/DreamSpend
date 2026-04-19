import 'package:go_router/go_router.dart';

import '../screens/achievements_screen.dart';
import '../screens/day_spends_screen.dart';
import '../screens/history_screen.dart';
import '../screens/home_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/today_screen.dart';
import '../state/game_store.dart';

GoRouter buildRouter(GameStore store) {
  return GoRouter(
    initialLocation: '/today',
    redirect: (context, state) {
      // Only redirect to onboarding if fully initialized and not shown yet
      if (!store.initialized) return null;
      if (!store.settings.onboardingShown &&
          state.fullPath != '/onboarding') {
        return '/onboarding';
      }
      return null;
    },
    refreshListenable: store,
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          GoRoute(
            path: '/today',
            builder: (context, state) => const TodayScreen(),
            routes: [
              GoRoute(
                path: 'day/:dayIndex',
                builder: (context, state) {
                  final idx = int.tryParse(
                        state.pathParameters['dayIndex'] ?? '',
                      ) ??
                      store.today.dayIndex;
                  return DaySpendsScreen(dayIndex: idx);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/history',
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: '/achievements',
            builder: (context, state) => const AchievementsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
}
