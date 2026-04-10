import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_strings.dart';
import 'navigation/app_router.dart';
import 'state/game_store.dart';
import 'theme/app_theme.dart';
import 'widgets/app_scope.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const X2FinancialGameApp());
}

class X2FinancialGameApp extends StatefulWidget {
  const X2FinancialGameApp({super.key});

  @override
  State<X2FinancialGameApp> createState() => _X2FinancialGameAppState();
}

class _X2FinancialGameAppState extends State<X2FinancialGameApp> {
  final store = GameStore();
  late final router = buildRouter(store);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!store.initialized) {
      store.init(WidgetsBinding.instance.platformDispatcher.locale);
    }
  }

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        if (!store.initialized) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final locale = Locale(store.settings.languageCode);

        return AppScope(
          notifier: store,
          child: StringsScope(
            locale: locale,
            child: MaterialApp.router(
              routerConfig: router,
              locale: locale,
              supportedLocales: AppStrings.supportedLocales,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              title: 'DreamSpend',
              theme: AppTheme.light(),
              builder: (context, child) {
                // Wrap every route in the background gradient
                return AppBackground(child: child ?? const SizedBox.shrink());
              },
            ),
          ),
        );
      },
    );
  }
}
