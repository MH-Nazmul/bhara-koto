import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A taximeter ring wrapped around the fare.
///
/// The arc shows how far into the current kilometre the bus is, so the number
/// in the middle is visibly *earning* rather than just sitting there — the ring
/// completes, the fare steps up, the ring restarts. It also gives the hero card
/// a reason to occupy the space it needs instead of parking a number in a void.
class FareDial extends StatelessWidget {
  const FareDial({
    super.key,
    required this.progress,
    required this.trackColor,
    required this.arcColor,
    required this.child,
    this.stroke = 7,
  });

  /// 0…1 through the current kilometre.
  final double progress;
  final Color trackColor;
  final Color arcColor;
  final double stroke;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final diameter = math.min(constraints.maxWidth, constraints.maxHeight)
            .clamp(160.0, 300.0);

        return Center(
          child: SizedBox(
            width: diameter,
            height: diameter,
            child: TweenAnimationBuilder<double>(
              // A jump backwards (the ring resetting at a whole kilometre) is
              // animated like any other move; at 400ms it reads as a sweep
              // rather than a glitch.
              tween: Tween(end: progress.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              builder: (context, value, _) => CustomPaint(
                painter: _DialPainter(
                  progress: value,
                  trackColor: trackColor,
                  arcColor: arcColor,
                  stroke: stroke,
                ),
                child: Padding(
                  // Keeps the contents clear of the ring on every diameter.
                  padding: EdgeInsets.all(diameter * 0.14),
                  child: Center(child: child),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DialPainter extends CustomPainter {
  const _DialPainter({
    required this.progress,
    required this.trackColor,
    required this.arcColor,
    required this.stroke,
  });

  final double progress;
  final Color trackColor;
  final Color arcColor;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (math.min(size.width, size.height) - stroke) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = trackColor;

    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = arcColor;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // 12 o'clock
      2 * math.pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.progress != progress ||
      old.arcColor != arcColor ||
      old.trackColor != trackColor ||
      old.stroke != stroke;
}
