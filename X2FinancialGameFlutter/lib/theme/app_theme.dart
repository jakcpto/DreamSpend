import 'package:flutter/material.dart';

/// Breakpoint for tablet/wide-screen adaptive layout.
const double kTabletBreakpoint = 720.0;
const double kTabletExtendedBreakpoint = 900.0;

/// Background gradient matching Swift's screen backgrounds.
const List<Color> kBackgroundGradient = [Color(0xFFF5F7FD), Color(0xFFEBF2FA)];

/// Onboarding gradient.
const List<Color> kOnboardingGradient = [Color(0xFFF2EEE0), Color(0xFFD6E3D6)];

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    return ThemeData(
      colorSchemeSeed: const Color(0xFF2EC27E),
      useMaterial3: true,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: Colors.white.withValues(alpha: 0.85),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      appBarTheme: const AppBarTheme(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withOpacity(0.92),
        elevation: 0,
        indicatorColor: const Color(0xFF2EC27E).withOpacity(0.18),
      ),
    );
  }
}

/// Wraps child in the standard background gradient used across screens.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: kBackgroundGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}
