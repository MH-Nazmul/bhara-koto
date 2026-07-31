import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A single dense line showing the rules the fare is being computed from, plus
/// where they came from. Tapping it goes to Settings.
///
/// It exists because a fare number nobody can audit is just a number — the user
/// should always see the rate that produced it without leaving the screen.
class RateStrip extends StatelessWidget {
  const RateStrip({
    super.key,
    required this.rateLabel,
    required this.minLabel,
    required this.sourceLabel,
    required this.sourceColor,
    required this.onTap,
    this.syncing = false,
  });

  final String rateLabel;
  final String minLabel;
  final String sourceLabel;
  final Color sourceColor;
  final VoidCallback onTap;
  final bool syncing;

  @override
  Widget build(BuildContext context) {
    final bk = context.bk;
    final text = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      borderRadius: BkRadius.medium,
      child: InkWell(
        borderRadius: BkRadius.medium,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              Icon(Icons.receipt_long_rounded, size: 14, color: bk.textFaint),
              const SizedBox(width: 8),
              // The rates take whatever the source badge doesn't need, rather
              // than competing with a Spacer and getting clipped.
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        rateLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                          color: bk.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    _Dot(color: bk.textFaint),
                    Flexible(
                      child: Text(
                        minLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                          color: bk.textSecondary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (syncing)
                SizedBox(
                  width: 11,
                  height: 11,
                  child: CircularProgressIndicator(strokeWidth: 1.6, color: bk.textFaint),
                )
              else
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: sourceColor, shape: BoxShape.circle),
                ),
              const SizedBox(width: 7),
              Text(
                sourceLabel,
                style: text.labelSmall?.copyWith(color: bk.textFaint, letterSpacing: 0.2),
              ),
              Icon(Icons.chevron_right_rounded, size: 16, color: bk.textFaint),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      );
}
