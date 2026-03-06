import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_strings.dart';
import 'screens/home_screen.dart';
import 'state/game_store.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!store.initialized) {
      store.init(WidgetsBinding.instance.platformDispatcher.locale);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        if (!store.initialized) {
          return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
        }

        final locale = Locale(store.settings.languageCode);

        return AppScope(
          notifier: store,
          child: StringsScope(
            locale: locale,
            child: MaterialApp(
              locale: locale,
              supportedLocales: AppStrings.supportedLocales,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              title: AppStrings(locale).t('appTitle'),
              theme: ThemeData(
                colorSchemeSeed: Colors.teal,
                useMaterial3: true,
              ),
              home: const HomeScreen(),
            ),
          ),
        );
      },
    );
  }
}
