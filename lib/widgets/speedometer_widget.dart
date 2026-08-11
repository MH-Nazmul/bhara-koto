import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class SpeedometerWidget extends StatelessWidget {
  const SpeedometerWidget({
    super.key,
    required this.speedMps,
    this.speedLimitKmh = 60.0,
  });

  final double speedMps;
  final double speedLimitKmh;

  @override
  Widget build(BuildContext context) {
    final bk = context.bk;
    final text = Theme.of(context).textTheme;
    final isBangla = Localizations.localeOf(context).languageCode == 'bn';
    final lang = isBangla ? 'bn' : 'en';

    final speedKmh = speedMps * 3.6;
    final isOverspeeding = speedKmh > speedLimitKmh;

    return Column(
      children: [
        if (isOverspeeding)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: bk.dangerSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: bk.danger),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.speed_rounded, color: bk.danger, size: 18),
                const SizedBox(width: 6),
                Text(
                  isBangla
                      ? 'গতিসীমা সতর্কতা! বাসের গতি ${Fmt.speedKmh(speedMps, lang)} km/h'
                      : 'Overspeed Warning! Bus speed: ${Fmt.speedKmh(speedMps, lang)} km/h',
                  style: text.bodySmall?.copyWith(
                    color: bk.danger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
