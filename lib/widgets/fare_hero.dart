import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'fare_dial.dart';
import 'surface_card.dart';

/// The centrepiece: state badge, the fare in the largest type the app owns
/// wrapped in a live meter ring, and the readings beneath it — one card, so the
/// screen reads as a single instrument rather than a pile of boxes.
class FareHero extends StatelessWidget {
  const FareHero({
    super.key,
    required this.statusPill,
    required this.currency,
    required this.amount,
    required this.caption,
    required this.metrics,
    required this.dialProgress,
    this.meteredAmount,
    this.isMinimumApplied = false,
    this.trailing,
    this.captionColor,
    this.highlight = false,
    this.dimmed = false,
  });

  final Widget statusPill;
  final Widget? trailing;
  final String currency;
  final String amount;
  final String? meteredAmount;
  final bool isMinimumApplied;
  final String caption;
  final Color? captionColor;
  final Widget metrics;

  /// 0…1 through the current kilometre — drives the ring.
  final double dialProgress;

  /// Stop detected: the card lights up so the fare is unmissable.
  final bool highlight;

  /// Before the first trip the number is a placeholder, not a result.
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final bk = context.bk;
    final text = Theme.of(context).textTheme;
    final amountColor = dimmed ? bk.textFaint : (highlight ? bk.accent : bk.textPrimary);

    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      borderColor: highlight ? bk.accent.withValues(alpha: 0.55) : bk.hairline,
      child: Column(
        children: [
          Row(
            children: [
              statusPill,
              const Spacer(),
              ?trailing,
            ],
          ),
          Expanded(
            child: FareDial(
              progress: dimmed ? 0 : dialProgress,
              trackColor: bk.hairline,
              arcColor: highlight ? bk.accent : (dimmed ? bk.textFaint : bk.accent),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: isMinimumApplied && meteredAmount != null
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$currency$meteredAmount',
                                style: text.displayLarge?.copyWith(
                                  fontSize: 34,
                                  letterSpacing: -1.2,
                                  color: bk.textSecondary,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: Colors.redAccent,
                                  decorationThickness: 2.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.arrow_forward_rounded, size: 20, color: bk.warning),
                              const SizedBox(width: 6),
                              Padding(
                                padding: const EdgeInsets.only(top: 4, right: 3),
                                child: Text(
                                  currency,
                                  style: text.displayMedium?.copyWith(
                                    fontSize: 22,
                                    color: amountColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                amount,
                                style: text.displayLarge?.copyWith(
                                  fontSize: 52,
                                  letterSpacing: -2.0,
                                  color: amountColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 9, right: 3),
                                child: Text(
                                  currency,
                                  style: text.displayMedium?.copyWith(
                                    fontSize: 24,
                                    color: dimmed ? bk.textFaint : bk.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                amount,
                                style: text.displayLarge?.copyWith(
                                  fontSize: 58,
                                  letterSpacing: -2.4,
                                  color: amountColor,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      caption,
                      key: ValueKey(caption),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        fontSize: 11.5,
                        height: 1.35,
                        color: captionColor ?? bk.textSecondary,
                        fontWeight: captionColor != null ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 14),
            child: Divider(height: 1, color: bk.hairline),
          ),
          metrics,
        ],
      ),
    );
  }
}
