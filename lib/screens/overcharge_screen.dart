import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/overcharge_report_model.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/surface_card.dart';

class OverchargeScreen extends StatefulWidget {
  const OverchargeScreen({
    super.key,
    required this.storage,
  });

  final StorageService storage;

  @override
  State<OverchargeScreen> createState() => _OverchargeScreenState();
}

class _OverchargeScreenState extends State<OverchargeScreen> {
  List<OverchargeReport> _reports = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  void _loadReports() {
    setState(() {
      _reports = widget.storage.readOverchargeReports();
    });
  }

  void _showReportModal() {
    final busController = TextEditingController();
    final spotController = TextEditingController();
    final demandedController = TextEditingController();
    final officialController = TextEditingController();
    final noteController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final isBangla = Localizations.localeOf(context).languageCode == 'bn';
        final bk = ctx.bk;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.report_problem_rounded, color: bk.danger),
                    const SizedBox(width: 8),
                    Text(
                      isBangla ? 'বাসের অতিরিক্ত ভাড়ার অভিযোগ দাখিল' : 'Report Overcharge Incident',
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: busController,
                  decoration: InputDecoration(
                    labelText: isBangla ? 'বাসের নাম / রুট' : 'Bus Name / Route',
                    hintText: isBangla ? 'যেমন: প্রভাতী বনশ্রী / বিকল্প' : 'e.g. Probhati Banasree',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: spotController,
                  decoration: InputDecoration(
                    labelText: isBangla ? 'স্থান / এলাকা' : 'Location Spot',
                    hintText: isBangla ? 'যেমন: ফার্মগেট থেকে শাহবাগ' : 'e.g. Farmgate to Shahbagh',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: demandedController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isBangla ? 'দাবি করা ভাড়া (৳)' : 'Demanded Fare (৳)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: officialController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isBangla ? 'সরকারী ভাড়া (৳)' : 'Official Fare (৳)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: isBangla ? 'অভিযোগের বিবরণ (ঐচ্ছিক)' : 'Details / Reason (Optional)',
                    hintText: isBangla ? 'যেমন: ওয়েবিলের অজুহাত দেখিয়েছে' : 'Reason for overcharge',
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bk.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.send_rounded),
                  label: Text(
                    isBangla ? 'অভিযোগ জমা দিন' : 'Submit Incident Report',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    if (busController.text.trim().isEmpty || demandedController.text.trim().isEmpty) {
                      return;
                    }

                    final report = OverchargeReport(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      busName: busController.text.trim(),
                      locationSpot: spotController.text.trim().isEmpty
                          ? (isBangla ? 'ঢাকা শহর' : 'Dhaka City')
                          : spotController.text.trim(),
                      demandedFare: double.tryParse(demandedController.text.trim()) ?? 0,
                      officialFare: double.tryParse(officialController.text.trim()) ?? 10,
                      timestamp: DateTime.now(),
                      note: noteController.text.trim(),
                    );

                    await widget.storage.addOverchargeReport(report);
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadReports();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bk = context.bk;
    final text = Theme.of(context).textTheme;
    final isBangla = Localizations.localeOf(context).languageCode == 'bn';
    final lang = isBangla ? 'bn' : 'en';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isBangla ? 'অতিরিক্ত ভাড়া ও অভিযোগ তালিকা' : 'Overcharge Complaints Feed',
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: bk.danger,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment_rounded),
        label: Text(isBangla ? 'অভিযোগ করুন' : 'Report Incident'),
        onPressed: _showReportModal,
      ),
      body: _reports.isEmpty
          ? Center(
              child: Text(
                isBangla ? 'কোন অভিযোগ জমা হয়নি' : 'No incident reports logged yet',
                style: text.bodyMedium?.copyWith(color: bk.textFaint),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _reports.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _reports[index];
                final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(item.timestamp);

                return SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: bk.dangerSoft,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.directions_bus_rounded, color: bk.danger, size: 18),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.busName,
                              style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: bk.dangerSoft,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '৳${Fmt.money(item.overchargeAmount, lang)} ${isBangla ? "অতিরিক্ত" : "Extra"}',
                              style: text.labelSmall?.copyWith(
                                color: bk.danger,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.place_rounded, size: 14, color: bk.textFaint),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.locationSpot,
                              style: text.bodySmall?.copyWith(color: bk.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            isBangla ? 'দাবি: ৳${Fmt.money(item.demandedFare, lang)}' : 'Demanded: ৳${Fmt.money(item.demandedFare, lang)}',
                            style: text.bodySmall?.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: bk.textFaint,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isBangla ? 'সরকারী: ৳${Fmt.money(item.officialFare, lang)}' : 'Official: ৳${Fmt.money(item.officialFare, lang)}',
                            style: text.bodySmall?.copyWith(
                              color: bk.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (item.note.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '"${item.note}"',
                          style: text.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: bk.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        dateStr,
                        style: text.bodySmall?.copyWith(color: bk.textFaint, fontSize: 10),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
