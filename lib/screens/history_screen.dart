import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../models/fare_config.dart';
import '../models/trip_history_model.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/calculator.dart';
import '../utils/formatters.dart';
import '../widgets/fare_receipt_dialog.dart';
import '../widgets/surface_card.dart';
import 'overcharge_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.storage,
    required this.config,
    required this.profile,
  });

  final StorageService storage;
  final FareConfig config;
  final FareProfile profile;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TripHistoryItem> _history = [];
  TripHistoryItem? _selectedTrip;

  // Point to Point Estimator state
  LatLngPoint? _pointA;
  LatLngPoint? _pointB;
  FareProfile _estimatorProfile = FareProfile.local;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _estimatorProfile = widget.profile;
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _history = widget.storage.readTripHistory();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          isBangla ? 'ভ্রমণ ইতিহাস ও মানচিত্র' : 'Trip History & Map',
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.history_rounded),
              text: isBangla ? 'ইতিহাস' : 'History List',
            ),
            Tab(
              icon: const Icon(Icons.map_rounded),
              text: isBangla ? 'দূরত্ব ও ভাড়া হিসেব' : 'Map & Estimator',
            ),
          ],
        ),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: isBangla ? 'ইতিহাস মুছুন' : 'Clear History',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(isBangla ? 'ইতিহাস মুছুন?' : 'Clear History?'),
                    content: Text(
                      isBangla
                          ? 'আপনি কি সমস্ত সংরক্ষিত ইতিহাস মুছে ফেলতে চান?'
                          : 'Are you sure you want to clear all recorded trips?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(isBangla ? 'বাতিল' : 'Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(isBangla ? 'মুছুন' : 'Clear'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await widget.storage.clearTripHistory();
                  _loadHistory();
                }
              },
            )
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHistoryList(context, bk, text, lang, isBangla),
          _buildMapEstimator(context, bk, text, lang, isBangla),
        ],
      ),
    );
  }

  Widget _buildHistoryList(
    BuildContext context,
    BkColors bk,
    TextTheme text,
    String lang,
    bool isBangla,
  ) {
    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_bus_outlined, size: 64, color: bk.textFaint),
            const SizedBox(height: 16),
            Text(
              isBangla ? 'কোন সংরক্ষিত ভ্রমণ ইতিহাস নেই' : 'No recorded trip history yet',
              style: text.bodyLarge?.copyWith(color: bk.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              isBangla
                  ? 'একটি যাত্রা শেষ হলে এখানে তার সমস্ত তথ্য জমা হবে'
                  : 'Start and complete a journey to see your route history here',
              style: text.bodySmall?.copyWith(color: bk.textFaint),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _history[index];
        final isLocal = item.profile == FareProfile.local;
        final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(item.startedAt);

        return SurfaceCard(
          child: ExpansionTile(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLocal ? bk.accentSoft : bk.warningSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isLocal
                        ? (isBangla ? 'লোকাল/সিটি' : 'Local')
                        : (isBangla ? 'দূরপাল্লা' : 'Intercity'),
                    style: text.labelSmall?.copyWith(
                      color: isLocal ? bk.accent : bk.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '৳ ${Fmt.money(item.fareTotal, lang)}',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: bk.accent,
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 14, color: bk.textFaint),
                  const SizedBox(width: 4),
                  Text(dateStr, style: text.bodySmall?.copyWith(color: bk.textFaint)),
                  const Spacer(),
                  Icon(Icons.straighten_rounded, size: 14, color: bk.textFaint),
                  const SizedBox(width: 4),
                  Text(
                    Fmt.distanceKm(item.distanceMeters, lang) + ' km',
                    style: text.bodySmall?.copyWith(color: bk.textSecondary),
                  ),
                ],
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(color: bk.hairline),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isBangla ? 'ভ্রমণের সময়কাল:' : 'Duration:',
                          style: text.bodySmall?.copyWith(color: bk.textFaint),
                        ),
                        Text(
                          Fmt.duration(item.duration, lang),
                          style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isBangla ? 'জিপিএস পয়েন্ট সংখ্যা:' : 'GPS Waypoints:',
                          style: text.bodySmall?.copyWith(color: bk.textFaint),
                        ),
                        Text(
                          '${item.routePoints.length}',
                          style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.receipt_long_rounded, size: 18),
                            label: Text(
                              isBangla ? 'রসিদ তৈরি' : 'Receipt',
                            ),
                            onPressed: () {
                              final rate = widget.config.rateFor(item.profile);
                              showDialog<void>(
                                context: context,
                                builder: (_) => FareReceiptDialog(
                                  distanceMeters: item.distanceMeters,
                                  fareProfile: item.profile,
                                  ratePerKm: rate.ratePerKm,
                                  minFare: rate.minFare,
                                  startedAt: item.startedAt,
                                  endedAt: item.endedAt,
                                  onReportOverchargePressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => OverchargeScreen(storage: widget.storage),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.map_rounded, size: 18),
                            label: Text(
                              isBangla ? 'রুট দেখুন' : 'Map Route',
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedTrip = item;
                                _tabController.animateTo(1);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapEstimator(
    BuildContext context,
    BkColors bk,
    TextTheme text,
    String lang,
    bool isBangla,
  ) {
    double distanceMeters = 0;
    if (_pointA != null && _pointB != null) {
      distanceMeters = Geolocator.distanceBetween(
        _pointA!.latitude,
        _pointA!.longitude,
        _pointB!.latitude,
        _pointB!.longitude,
      );
    }

    final rate = widget.config.rateFor(_estimatorProfile);
    final breakdown = FareCalculator.compute(
      distanceMeters: distanceMeters,
      rate: rate,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selector header
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBangla
                      ? 'দুই পয়েন্টের দূরত্ব ও আনুমানিক ভাড়া'
                      : 'Two-Point Distance & Fare Calculator',
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  isBangla
                      ? 'মানচিত্রে দুটি স্থান নির্বাচন করুন বা আপনার ইতিহাস থেকে বিন্দু বসান'
                      : 'Select two points below or tap on the canvas to estimate fare between 2 points',
                  style: text.bodySmall?.copyWith(color: bk.textFaint),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(
                          Icons.location_on_rounded,
                          color: _pointA != null ? Colors.green : null,
                          size: 18,
                        ),
                        label: Text(
                          _pointA == null
                              ? (isBangla ? 'পয়েন্ট ১ সেট (ধানমন্ডি)' : 'Set Point A')
                              : 'A: ${_pointA!.latitude.toStringAsFixed(3)}, ${_pointA!.longitude.toStringAsFixed(3)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () {
                          setState(() {
                            // Default preset Point A (Dhanmondi / Dhaka centre)
                            _pointA = const LatLngPoint(23.7461, 90.3742);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(
                          Icons.flag_rounded,
                          color: _pointB != null ? Colors.redAccent : null,
                          size: 18,
                        ),
                        label: Text(
                          _pointB == null
                              ? (isBangla ? 'পয়েন্ট ২ সেট (ফার্মগেট)' : 'Set Point B')
                              : 'B: ${_pointB!.latitude.toStringAsFixed(3)}, ${_pointB!.longitude.toStringAsFixed(3)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () {
                          setState(() {
                            // Default preset Point B (Farmgate ~ 3.5 km)
                            _pointB = const LatLngPoint(23.7561, 90.3872);
                          });
                        },
                      ),
                    ),
                  ],
                ),
                if (_pointA != null || _pointB != null) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(isBangla ? 'পুনরায় সেট করুন' : 'Reset Points'),
                    onPressed: () {
                      setState(() {
                        _pointA = null;
                        _pointB = null;
                      });
                    },
                  ),
                ]
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Map Canvas Simulation
          SurfaceCard(
            child: AspectRatio(
              aspectRatio: 1.6,
              child: CustomPaint(
                painter: _MapRoutePainter(
                  pointA: _pointA,
                  pointB: _pointB,
                  trip: _selectedTrip,
                  bk: bk,
                ),
                child: InkWell(
                  onTapDown: (details) {
                    // Tap on canvas to set A then B
                    final box = context.findRenderObject() as RenderBox?;
                    if (box == null) return;
                    final size = box.size;
                    final dx = details.localPosition.dx / size.width;
                    final dy = details.localPosition.dy / size.height;
                    final lat = 23.75 + (0.5 - dy) * 0.1;
                    final lng = 90.38 + (dx - 0.5) * 0.1;
                    setState(() {
                      if (_pointA == null || (_pointA != null && _pointB != null)) {
                        _pointA = LatLngPoint(lat, lng);
                        _pointB = null;
                      } else {
                        _pointB = LatLngPoint(lat, lng);
                      }
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Fare Result Card
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isBangla ? 'ভাড়া বিশ্লেষণ' : 'Fare Calculation',
                      style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SegmentedButton<FareProfile>(
                      segments: [
                        ButtonSegment(
                          value: FareProfile.local,
                          label: Text(isBangla ? 'লোকাল' : 'Local'),
                        ),
                        ButtonSegment(
                          value: FareProfile.intercity,
                          label: Text(isBangla ? 'দূরপাল্লা' : 'Intercity'),
                        ),
                      ],
                      selected: {_estimatorProfile},
                      onSelectionChanged: (set) {
                        setState(() {
                          _estimatorProfile = set.first;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isBangla ? 'মোট দূরত্ব' : 'Total Distance',
                            style: text.bodySmall?.copyWith(color: bk.textFaint),
                          ),
                          Text(
                            '${Fmt.distanceKm(breakdown.distanceMeters, lang)} km',
                            style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isBangla ? 'প্রদেয় ভাড়া' : 'Payable Fare',
                            style: text.bodySmall?.copyWith(color: bk.textFaint),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (breakdown.minimumApplied) ...[
                                Text(
                                  '৳${Fmt.money(breakdown.metered, lang)}',
                                  style: text.titleMedium?.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: Colors.redAccent,
                                    color: bk.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(Icons.arrow_forward_rounded, size: 16, color: bk.warning),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                '৳${Fmt.money(breakdown.total, lang)}',
                                style: text.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: bk.accent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (breakdown.minimumApplied) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: bk.warningSoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isBangla
                          ? 'মিটারে নির্ণীত ভাড়া ৳${Fmt.money(breakdown.metered, lang)} বিআরটিএ-র সর্বনিম্ন ভাড়া ৳১০.০০ এর চেয়ে কম হওয়ায় সর্বনিম্ন ভাড়া প্রযোজ্য।'
                          : 'Metered fare ৳${Fmt.money(breakdown.metered, lang)} is below BRTA minimum fare threshold (৳10.00). Minimum fare applies.',
                      style: text.bodySmall?.copyWith(color: bk.warning, fontSize: 11),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapRoutePainter extends CustomPainter {
  _MapRoutePainter({
    required this.pointA,
    required this.pointB,
    required this.trip,
    required this.bk,
  });

  final LatLngPoint? pointA;
  final LatLngPoint? pointB;
  final TripHistoryItem? trip;
  final BkColors bk;

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = bk.surfaceRaised;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(12)),
      bgPaint,
    );

    // Draw Grid Lines representing map grid
    final gridPaint = Paint()
      ..color = bk.hairline
      ..strokeWidth = 1.0;
    for (double i = 20; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double j = 20; j < size.height; j += 40) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), gridPaint);
    }

    final pA = pointA != null ? Offset(size.width * 0.3, size.height * 0.6) : null;
    final pB = pointB != null ? Offset(size.width * 0.7, size.height * 0.3) : null;

    if (pA != null && pB != null) {
      final linePaint = Paint()
        ..color = bk.accent
        ..strokeWidth = 4.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(pA, pB, linePaint);
    }

    if (pA != null) {
      final pointAPaint = Paint()..color = Colors.green;
      canvas.drawCircle(pA, 8, pointAPaint);
    }

    if (pB != null) {
      final pointBPaint = Paint()..color = Colors.redAccent;
      canvas.drawCircle(pB, 8, pointBPaint);
    }

    if (pA == null && pB == null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'Tap on canvas or set Points A & B to preview distance',
          style: TextStyle(color: bk.textFaint, fontSize: 12),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
