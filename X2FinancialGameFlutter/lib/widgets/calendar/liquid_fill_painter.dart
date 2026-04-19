import 'dart:math';

import 'package:flutter/material.dart';

/// Seeded pseudo-random using xorshift64 — matches Swift's SeededRandom.
class _SeededRandom {
  _SeededRandom(int seed) : _state = seed ^ 0x9E3779B97F4A7C15;

  int _state;

  double nextDouble() {
    _state ^= _state << 13;
    _state ^= _state >> 7;
    _state ^= _state << 17;
    return (_state.abs() & 0x7FFFFFFF) / 0x7FFFFFFF;
  }
}

/// CustomPainter rendering a liquid-fill effect inside a rounded tile.
///
/// [progress] — 0.0 to 1.0+ (can exceed 1.0 for overspend zone)
/// [fillColor] — the color of the liquid
/// [phase] — animation phase driven by AnimationController (radians)
/// [bubbleSeed] — stable seed for bubble positions per tile
class LiquidFillPainter extends CustomPainter {
  LiquidFillPainter({
    required this.progress,
    required this.fillColor,
    required this.phase,
    required this.bubbleSeed,
    this.cornerRadius = 11,
  });

  final double progress;
  final Color fillColor;
  final double phase;
  final int bubbleSeed;
  final double cornerRadius;

  static const int _bubbleCount = 10;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final clampedProgress = progress.clamp(0.0, 1.05);
    final fillHeight = size.height * clampedProgress;
    final fillTop = size.height - fillHeight;

    // Clip to the rounded rectangle of the tile
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(cornerRadius),
    );
    canvas.save();
    canvas.clipRRect(rrect);

    final paint = Paint()
      ..color = fillColor.withOpacity(0.72)
      ..style = PaintingStyle.fill;

    // --- Wave path ---
    final amplitude = (size.height * 0.05).clamp(2.0, 8.0);
    final steps = max(24, (size.width / 6).round());
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, fillTop);

    for (int i = 0; i <= steps; i++) {
      final x = (i / steps) * size.width;
      final y = fillTop + sin((i / steps) * 2 * pi + phase) * amplitude;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);

    // --- Bubbles ---
    final rng = _SeededRandom(bubbleSeed);
    final bubblePaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.plus;

    for (int b = 0; b < _bubbleCount; b++) {
      final base = rng.nextDouble(); // stable base x
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final radius = 2.0 + rng.nextDouble() * 4.0;

      final bx = base * size.width;
      // Progress through liquid from bottom to wave surface
      final t = (phase * speed / (2 * pi) + base * 4) % 1.2;
      final tClamped = t.clamp(0.0, 1.0);
      final by = size.height - tClamped * fillHeight + fillTop * 0.05;

      if (by < fillTop - radius) continue; // above wave: skip

      canvas.drawCircle(Offset(bx, by), radius, bubblePaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(LiquidFillPainter old) =>
      old.phase != phase ||
      old.progress != progress ||
      old.fillColor != fillColor;
}
