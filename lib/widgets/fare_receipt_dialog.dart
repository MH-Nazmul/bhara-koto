import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/fare_config.dart';
import '../theme/app_theme.dart';
import '../utils/calculator.dart';
import '../utils/formatters.dart';
import 'surface_card.dart';

class FareReceiptDialog extends StatefulWidget {
  const FareReceiptDialog({
    super.key,
    required this.distanceMeters,
    required this.fareProfile,
    required this.ratePerKm,
    required this.minFare,
    required this.startedAt,
    required this.endedAt,
    this.onReportOverchargePressed,
  });

  final double distanceMeters;
  final FareProfile fareProfile;
  final double ratePerKm;
  final double minFare;
  final DateTime startedAt;
  final DateTime endedAt;
  final VoidCallback? onReportOverchargePressed;

  @override
  State<FareReceiptDialog> createState() => _FareReceiptDialogState();
}

class _FareReceiptDialogState extends State<FareReceiptDialog> {
  final TextEditingController _demandedFareController = TextEditingController();
  double? _demandedFare;

  @override
  void dispose() {
    _demandedFareController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bk = context.bk;
    final text = Theme.of(context).textTheme;
    final isBangla = Localizations.localeOf(context).languageCode == 'bn';
    final lang = isBangla ? 'bn' : 'en';

    final breakdown = FareCalculator.compute(
      distanceMeters: widget.distanceMeters,
      rate: FareRate(ratePerKm: widget.ratePerKm, minFare: widget.minFare),
    );

    final isLocal = widget.fareProfile == FareProfile.local;
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(widget.startedAt);
    final duration = widget.endedAt.difference(widget.startedAt);

    final overcharge = _demandedFare != null ? (_demandedFare! - breakdown.total).clamp(0, double.infinity) : 0.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bk.accentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.receipt_long_rounded, color: bk.accent, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBangla ? 'বিআরটিএ অফিসিয়াল ভাড়া রসিদ' : 'BRTA Official Fare Receipt',
                        style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isBangla ? 'বাংলাদেশ সড়ক পরিবহন কর্তৃপক্ষ নির্দেশিকা' : 'Bangladesh Road Transport Authority',
                        style: text.bodySmall?.copyWith(color: bk.textFaint, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),

            // Ticket Body
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bk.surfaceRaised,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: bk.hairline),
              ),
              child: Column(
                children: [
                  _rowItem(context, isBangla ? 'তারিখ ও সময়:' : 'Date & Time:', dateStr),
                  const SizedBox(height: 8),
                  _rowItem(
                    context,
                    isBangla ? 'বাসের ধরন:' : 'Bus Service:',
                    isLocal ? (isBangla ? 'লোকাল / সিটি বাস' : 'Local / City Bus') : (isBangla ? 'দূরপাল্লা (কোচ)' : 'Intercity Coach'),
                  ),
                  const SizedBox(height: 8),
                  _rowItem(
                    context,
                    isBangla ? 'বিআরটিএ কিলোমিটার হার:' : 'BRTA Rate / km:',
                    '৳ ${Fmt.rate(widget.ratePerKm, lang)} / km',
                  ),
                  const SizedBox(height: 8),
                  _rowItem(
                    context,
                    isBangla ? 'মোট অতিক্রান্ত দূরত্ব:' : 'Distance Traveled:',
                    '${Fmt.distanceKm(widget.distanceMeters, lang)} km',
                  ),
                  const SizedBox(height: 8),
                  _rowItem(
                    context,
                    isBangla ? 'ভ্রমণের সময়কাল:' : 'Trip Duration:',
                    Fmt.duration(duration, lang),
                  ),
                  const Divider(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isBangla ? 'আইনসম্মত প্রদেয় ভাড়া:' : 'Official Fare:',
                        style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '৳ ${Fmt.money(breakdown.total, lang)}',
                        style: text.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: bk.accent,
                        ),
                      ),
                    ],
                  ),
                  if (breakdown.minimumApplied) ...[
                    const SizedBox(height: 6),
                    Text(
                      isBangla
                          ? '* মিটারে নির্ণীত ভাড়া ৳${Fmt.money(breakdown.metered, lang)} (সর্বনিম্ন ভাড়া ৳১০ প্রযোজ্য)'
                          : '* Metered fare ৳${Fmt.money(breakdown.metered, lang)} (Min fare ৳10 applied)',
                      style: text.bodySmall?.copyWith(color: bk.warning, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Optional Demanded Fare Dispute Check
            Text(
              isBangla ? 'কন্ডাক্টর কত ভাড়া চেয়েছে? (ঐচ্ছিক)' : 'How much did conductor demand? (Optional)',
              style: text.bodySmall?.copyWith(color: bk.textSecondary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _demandedFareController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: isBangla ? 'যেমন: ২৫' : 'e.g. 25',
                prefixText: '৳ ',
                isDense: true,
              ),
              onChanged: (val) {
                setState(() {
                  _demandedFare = double.tryParse(val);
                });
              },
            ),

            if (_demandedFare != null && overcharge > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bk.dangerSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_rounded, color: bk.danger, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isBangla
                            ? 'অতিরিক্ত দাবি করা হয়েছে: ৳ ${Fmt.money(overcharge.toDouble(), lang)} (বেআইনি)'
                            : 'Illegal Overcharge: ৳ ${Fmt.money(overcharge.toDouble(), lang)}',
                        style: text.bodySmall?.copyWith(color: bk.danger, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: Text(isBangla ? 'শেয়ার রসিদ' : 'Share Receipt'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isBangla
                                ? 'রসিদ কপি তৈরি হয়েছে! কন্ডাক্টরকে দেখান।'
                                : 'Receipt generated! Ready to show conductor.',
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (widget.onReportOverchargePressed != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: bk.danger,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.report_problem_rounded, size: 18),
                      label: Text(isBangla ? 'অভিযোগ করুন' : 'Report Issue'),
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onReportOverchargePressed!();
                      },
                    ),
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowItem(BuildContext context, String label, String value) {
    final text = Theme.of(context).textTheme;
    final bk = context.bk;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: text.bodySmall?.copyWith(color: bk.textFaint)),
        Text(value, style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: bk.textPrimary)),
      ],
    );
  }
}
