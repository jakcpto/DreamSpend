import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../widgets/app_scope.dart';

class CelebrationScreen extends StatefulWidget {
  const CelebrationScreen({super.key});

  @override
  State<CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends State<CelebrationScreen> {
  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 6));
    _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final strings = AppStrings.of(context);

    return Scaffold(
      backgroundColor: Colors.black54,
      body: Stack(
        children: [
          // Confetti from top center
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              gravity: 0.18,
              emissionFrequency: 0.08,
              colors: const [
                Color(0xFF2EC27E),
                Color(0xFF4A90D9),
                Color(0xFFE8A020),
                Color(0xFFE85D9A),
                Color(0xFF5C5FBA),
                Color(0xFFD94040),
              ],
            ),
          ),
          // Content
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 40,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '🏆',
                    style: TextStyle(fontSize: 80),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    strings.t('celebration.title'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.t('celebration.subtitle'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        store.restartGame();
                        Navigator.of(context).pop();
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(strings.t('celebration.restart')),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      store.dismissCelebration();
                      Navigator.of(context).pop();
                    },
                    child: Text(strings.t('celebration.close')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
