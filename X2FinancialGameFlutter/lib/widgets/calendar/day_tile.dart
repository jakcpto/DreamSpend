import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/game_models.dart';
import 'liquid_fill_painter.dart';

const double _kTileSize = 92.0;
const double _kTileRadius = 11.0;

/// Computes the liquid fill color based on fill ratio.
Color tileProgressColor(double ratio) {
  if (ratio <= 0.45) return const Color(0xFFD94040); // red
  if (ratio <= 0.90) return const Color(0xFFE8A020); // orange
  if (ratio <= 1.01) return const Color(0xFF2EC27E); // green
  return const Color(0xFF880022); // burgundy (overspend)
}

/// A single calendar day tile with optional liquid fill animation.
class DayTile extends StatefulWidget {
  const DayTile({
    super.key,
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.formatMoney,
    required this.onSelected,
    required this.onEditRequested,
    this.liquidEffect = true,
  });

  final DayEntry day;
  final bool isSelected;
  final bool isToday;
  final String Function(int minor, String currency) formatMoney;
  final VoidCallback onSelected;
  final VoidCallback onEditRequested;
  final bool liquidEffect;

  @override
  State<DayTile> createState() => _DayTileState();
}

class _DayTileState extends State<DayTile> with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    final ratio = day.fillRatio;
    final isMissed = day.status == DayStatus.missed;
    final isFilled = day.status == DayStatus.filled;

    final progressColor = tileProgressColor(ratio);
    final borderColor = widget.isSelected
        ? Theme.of(context).colorScheme.primary
        : isMissed
            ? Colors.orange.withOpacity(0.4)
            : Colors.grey.withOpacity(0.22);

    final bgColor = widget.isSelected
        ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
        : isMissed
            ? Colors.orange.withOpacity(0.08)
            : Colors.white.withOpacity(0.55);

    // Date label
    final date = day.date;
    final dayLabel = DateFormat('d').format(date);
    final monthLabel = DateFormat('MMM').format(date).toUpperCase();

    // Money label — compact
    final moneyText = _compactMoney(day.dailyLimitMinor, day.currencyCode);

    return GestureDetector(
      onTap: widget.onSelected,
      onLongPress: widget.onEditRequested,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _kTileSize,
        height: _kTileSize,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(_kTileRadius),
          border: Border.all(color: borderColor, width: widget.isSelected ? 2 : 1),
          boxShadow: widget.isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_kTileRadius),
          child: Stack(
            children: [
              // Liquid fill
              if (widget.liquidEffect && (isFilled || ratio > 0))
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _waveController,
                    builder: (_, __) => CustomPaint(
                      painter: LiquidFillPainter(
                        progress: ratio,
                        fillColor: progressColor,
                        phase: _waveController.value * 2 * pi * 1.2,
                        bubbleSeed: day.dayIndex * 137,
                        cornerRadius: _kTileRadius,
                      ),
                    ),
                  ),
                )
              else if (!widget.liquidEffect && ratio > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: _kTileSize * ratio.clamp(0.0, 1.0),
                  child: Container(
                    color: progressColor.withOpacity(0.55),
                  ),
                ),

              // Glass overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white
                        .withOpacity(widget.isSelected ? 0.18 : 0.10),
                    borderRadius: BorderRadius.circular(_kTileRadius),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Day index badge + today indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: widget.isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.black.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${day.dayIndex}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: widget.isSelected
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        if (widget.isToday)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),

                    // Date
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dayLabel,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: widget.isSelected || (isFilled && ratio > 0.5)
                                ? Colors.white
                                : Colors.black87,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          monthLabel,
                          style: TextStyle(
                            fontSize: 9,
                            color: widget.isSelected || (isFilled && ratio > 0.5)
                                ? Colors.white70
                                : Colors.black45,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),

                    // Amount
                    Text(
                      moneyText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: widget.isSelected || (isFilled && ratio > 0.5)
                            ? Colors.white
                            : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Missed X overlay
              if (isMissed)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: Colors.orange.shade700,
                  ),
                ),

              // Filled checkmark
              if (isFilled)
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _compactMoney(int minor, String currency) {
    final value = minor / 100;
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }
}
