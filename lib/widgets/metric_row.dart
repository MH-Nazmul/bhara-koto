import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// One reading: a faint label above a value with its unit set smaller and
/// lighter, so the eye lands on the number first.
class MetricCell extends StatelessWidget {
  const MetricCell({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.emphasis = false,
  });

  final String label;
  final String value;
  final String? unit;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final bk = context.bk;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.labelSmall?.copyWith(color: bk.textFaint),
        ),
        const SizedBox(height: 5),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: emphasis ? bk.accent : bk.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            if (unit != null) ...[
              const SizedBox(width: 3),
              Text(
                unit!,
                style: text.bodySmall?.copyWith(color: bk.textFaint, fontSize: 11),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Evenly divided readings separated by hairlines — cheaper on space than three
/// separate cards and it reads as one instrument.
class MetricRow extends StatelessWidget {
  const MetricRow({super.key, required this.cells});

  final List<MetricCell> cells;

  @override
  Widget build(BuildContext context) {
    final bk = context.bk;
    final children = <Widget>[];

    for (var i = 0; i < cells.length; i++) {
      children.add(Expanded(child: cells[i]));
      if (i != cells.length - 1) {
        children.add(
          Container(
            width: 1,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: bk.hairline,
          ),
        );
      }
    }

    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: children);
  }
}
