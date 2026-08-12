import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as ll;

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
  final MapController _mapController = MapController();

  List<TripHistoryItem> _history = [];
  TripHistoryItem? _selectedTrip;

  // Route waypoint indices when viewing a trip
  int? _indexA;
  int? _indexB;

  // Point to Point Estimator state (custom points when not using route points)
  ll.LatLng? _customPointA;
  ll.LatLng? _customPointB;
  FareProfile _estimatorProfile = FareProfile.local;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _estimatorProfile = widget.profile;
    _loadHistory();
  }

  void _loadHistory() {
    final history = widget.storage.readTripHistory();
    setState(() {
      _history = history;
      if (_selectedTrip == null && history.isNotEmpty) {
        _selectedTrip = history.first;
        if (history.first.routePoints.isNotEmpty) {
          _indexA = 0;
          _indexB = history.first.routePoints.length - 1;
        }
      }
    });
  }

  void _selectTrip(TripHistoryItem? trip) {
    setState(() {
      _selectedTrip = trip;
      _customPointA = null;
      _customPointB = null;
      if (trip != null) {
        _estimatorProfile = trip.profile;
        if (trip.routePoints.isNotEmpty) {
          _indexA = 0;
          _indexB = trip.routePoints.length - 1;
        } else {
          _indexA = null;
          _indexB = null;
        }
      } else {
        _indexA = null;
        _indexB = null;
      }
    });

    if (trip != null && trip.routePoints.isNotEmpty) {
      final pts = trip.routePoints.map((p) => ll.LatLng(p.latitude, p.longitude)).toList();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitMapToPoints(pts);
      });
    }
  }

  void _fitMapToPoints(List<ll.LatLng> points) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      _mapController.move(points.first, 15.0);
      return;
    }
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(40.0),
      ),
    );
  }

  ll.LatLng? get _effectivePointA {
    if (_customPointA != null) return _customPointA;
    if (_selectedTrip != null && _selectedTrip!.routePoints.isNotEmpty) {
      final idx = (_indexA ?? 0).clamp(0, _selectedTrip!.routePoints.length - 1);
      final p = _selectedTrip!.routePoints[idx];
      return ll.LatLng(p.latitude, p.longitude);
    }
    return null;
  }

  ll.LatLng? get _effectivePointB {
    if (_customPointB != null) return _customPointB;
    if (_selectedTrip != null && _selectedTrip!.routePoints.isNotEmpty) {
      final idx = (_indexB ?? (_selectedTrip!.routePoints.length - 1)).clamp(0, _selectedTrip!.routePoints.length - 1);
      final p = _selectedTrip!.routePoints[idx];
      return ll.LatLng(p.latitude, p.longitude);
    }
    return null;
  }

  double _calculateSelectedDistance() {
    if (_customPointA != null && _customPointB != null) {
      return Geolocator.distanceBetween(
        _customPointA!.latitude,
        _customPointA!.longitude,
        _customPointB!.latitude,
        _customPointB!.longitude,
      );
    }

    if (_selectedTrip != null && _selectedTrip!.routePoints.length > 1 && _customPointA == null && _customPointB == null) {
      final iA = (_indexA ?? 0).clamp(0, _selectedTrip!.routePoints.length - 1);
      final iB = (_indexB ?? (_selectedTrip!.routePoints.length - 1)).clamp(0, _selectedTrip!.routePoints.length - 1);
      final start = math.min(iA, iB);
      final end = math.max(iA, iB);

      if (start == 0 && end == _selectedTrip!.routePoints.length - 1) {
        return _selectedTrip!.distanceMeters;
      }

      double sum = 0;
      final pts = _selectedTrip!.routePoints;
      for (int k = start; k < end; k++) {
        sum += Geolocator.distanceBetween(
          pts[k].latitude,
          pts[k].longitude,
          pts[k + 1].latitude,
          pts[k + 1].longitude,
        );
      }
      return sum;
    }

    final pA = _effectivePointA;
    final pB = _effectivePointB;
    if (pA != null && pB != null) {
      return Geolocator.distanceBetween(
        pA.latitude,
        pA.longitude,
        pB.latitude,
        pB.longitude,
      );
    }
    return 0;
  }

  List<ll.LatLng> get _fullRoutePolyline {
    if (_selectedTrip == null || _selectedTrip!.routePoints.isEmpty) return [];
    return _selectedTrip!.routePoints.map((p) => ll.LatLng(p.latitude, p.longitude)).toList();
  }

  List<ll.LatLng> get _subRoutePolyline {
    if (_selectedTrip != null && _selectedTrip!.routePoints.length > 1 && _customPointA == null && _customPointB == null) {
      final iA = (_indexA ?? 0).clamp(0, _selectedTrip!.routePoints.length - 1);
      final iB = (_indexB ?? (_selectedTrip!.routePoints.length - 1)).clamp(0, _selectedTrip!.routePoints.length - 1);
      final start = math.min(iA, iB);
      final end = math.max(iA, iB);
      return _selectedTrip!.routePoints
          .sublist(start, end + 1)
          .map((p) => ll.LatLng(p.latitude, p.longitude))
          .toList();
    }

    final pA = _effectivePointA;
    final pB = _effectivePointB;
    if (pA != null && pB != null) {
      return [pA, pB];
    }
    return [];
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mapController.dispose();
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
                  setState(() {
                    _selectedTrip = null;
                    _indexA = null;
                    _indexB = null;
                    _customPointA = null;
                    _customPointB = null;
                  });
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
                    '${Fmt.distanceKm(item.distanceMeters, lang)} km',
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
                              isBangla ? 'মানচিত্রে দেখুন' : 'Map Route',
                            ),
                            onPressed: () {
                              _selectTrip(item);
                              _tabController.animateTo(1);
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
    final distanceMeters = _calculateSelectedDistance();
    final rate = widget.config.rateFor(_estimatorProfile);
    final breakdown = FareCalculator.compute(
      distanceMeters: distanceMeters,
      rate: rate,
    );

    final hasRoutePoints = _selectedTrip != null && _selectedTrip!.routePoints.isNotEmpty;
    final routePointCount = hasRoutePoints ? _selectedTrip!.routePoints.length : 0;

    final pA = _effectivePointA;
    final pB = _effectivePointB;

    final fullPolyline = _fullRoutePolyline;
    final subPolyline = _subRoutePolyline;

    // Initial center for map
    final initialCenter = pA ??
        (fullPolyline.isNotEmpty ? fullPolyline.first : const ll.LatLng(23.7461, 90.3742));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trip Selector & Header
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isBangla
                                ? 'মানচিত্রে অবস্থান ও ভাড়া হিসেব'
                                : 'Map Route & Fare Estimator',
                            style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isBangla
                                ? 'ভ্রমণ ইতিহাস থেকে পয়েন্ট বা মানচিত্রে ট্যাপ করে ২ বিন্দুর দূরত্ব ও ভাড়া দেখুন'
                                : 'Select trip history or tap on map to pick 2 points and estimate fare',
                            style: text.bodySmall?.copyWith(color: bk.textFaint),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_history.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TripHistoryItem?>(
                    initialValue: _selectedTrip,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: isBangla ? 'ভ্রমণ নির্বাচন করুন' : 'Select Trip History',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: [
                      DropdownMenuItem<TripHistoryItem?>(
                        value: null,
                        child: Text(
                          isBangla ? '-- কাস্টম মানচিত্র পয়েন্ট --' : '-- Custom Map Points --',
                          style: text.bodyMedium?.copyWith(color: bk.textFaint),
                        ),
                      ),
                      ..._history.map(
                        (trip) => DropdownMenuItem<TripHistoryItem?>(
                          value: trip,
                          child: Text(
                            '${DateFormat('dd MMM hh:mm a').format(trip.startedAt)} • ${Fmt.distanceKm(trip.distanceMeters, lang)} km (৳${Fmt.money(trip.fareTotal, lang)})',
                            style: text.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (trip) => _selectTrip(trip),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Route Points Slider (if a recorded trip is selected)
          if (hasRoutePoints && routePointCount > 1) ...[
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isBangla ? 'ভ্রমণ থেকে ২ পয়েন্ট নির্বাচন' : 'Pick Sub-Segment from Route',
                        style: text.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _customPointA = null;
                            _customPointB = null;
                            _indexA = 0;
                            _indexB = routePointCount - 1;
                          });
                          _fitMapToPoints(fullPolyline);
                        },
                        child: Text(
                          isBangla ? 'সম্পূর্ণ রুট' : 'Full Trip',
                          style: text.labelSmall?.copyWith(color: bk.accent, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  RangeSlider(
                    values: RangeValues(
                      ((_indexA ?? 0).clamp(0, routePointCount - 1)).toDouble(),
                      ((_indexB ?? (routePointCount - 1)).clamp(0, routePointCount - 1)).toDouble(),
                    ),
                    min: 0,
                    max: (routePointCount - 1).toDouble(),
                    divisions: routePointCount > 1 ? routePointCount - 1 : 1,
                    activeColor: bk.accent,
                    inactiveColor: bk.hairline,
                    labels: RangeLabels(
                      'P1 (#${(_indexA ?? 0) + 1})',
                      'P2 (#${(_indexB ?? (routePointCount - 1)) + 1})',
                    ),
                    onChanged: (values) {
                      setState(() {
                        _customPointA = null;
                        _customPointB = null;
                        _indexA = values.start.round();
                        _indexB = values.end.round();
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'A: #${(_indexA ?? 0) + 1} (${pA != null ? '${pA.latitude.toStringAsFixed(3)}, ${pA.longitude.toStringAsFixed(3)}' : ''})',
                        style: text.bodySmall?.copyWith(color: Colors.green, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'B: #${(_indexB ?? (routePointCount - 1)) + 1} (${pB != null ? '${pB.latitude.toStringAsFixed(3)}, ${pB.longitude.toStringAsFixed(3)}' : ''})',
                        style: text.bodySmall?.copyWith(color: Colors.redAccent, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Interactive Map Card
          SurfaceCard(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 320,
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: initialCenter,
                            initialZoom: 13.0,
                            onTap: (tapPos, latLng) {
                              setState(() {
                                if (_customPointA == null || (_customPointA != null && _customPointB != null)) {
                                  _customPointA = latLng;
                                  _customPointB = null;
                                } else {
                                  _customPointB = latLng;
                                }
                              });
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.bharakoto.bhara_koto',
                            ),
                            // Full Trip Polyline
                            if (fullPolyline.isNotEmpty)
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: fullPolyline,
                                    color: Colors.blueAccent.withValues(alpha: 0.6),
                                    strokeWidth: 4.0,
                                  ),
                                ],
                              ),
                            // Selected Sub-route Polyline
                            if (subPolyline.isNotEmpty)
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: subPolyline,
                                    color: Colors.amber.shade700,
                                    strokeWidth: 6.0,
                                  ),
                                ],
                              ),
                            // Marker Layer
                            MarkerLayer(
                              markers: [
                                // Trip Start Marker
                                if (fullPolyline.isNotEmpty)
                                  Marker(
                                    point: fullPolyline.first,
                                    width: 32,
                                    height: 32,
                                    child: const Icon(
                                      Icons.flag_rounded,
                                      color: Colors.green,
                                      size: 28,
                                    ),
                                  ),
                                // Trip End Marker
                                if (fullPolyline.isNotEmpty)
                                  Marker(
                                    point: fullPolyline.last,
                                    width: 32,
                                    height: 32,
                                    child: const Icon(
                                      Icons.sports_score_rounded,
                                      color: Colors.redAccent,
                                      size: 28,
                                    ),
                                  ),
                                // Selected Point A
                                if (pA != null)
                                  Marker(
                                    point: pA,
                                    width: 36,
                                    height: 36,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'A',
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ),
                                    ),
                                  ),
                                // Selected Point B
                                if (pB != null)
                                  Marker(
                                    point: pB,
                                    width: 36,
                                    height: 36,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.redAccent,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'B',
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        // Floating Controls Overlay
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Column(
                            children: [
                              FloatingActionButton.small(
                                heroTag: 'zoomInBtn',
                                backgroundColor: Theme.of(context).cardColor,
                                child: Icon(Icons.add_rounded, color: bk.textPrimary),
                                onPressed: () {
                                  _mapController.move(
                                    _mapController.camera.center,
                                    _mapController.camera.zoom + 1,
                                  );
                                },
                              ),
                              const SizedBox(height: 6),
                              FloatingActionButton.small(
                                heroTag: 'zoomOutBtn',
                                backgroundColor: Theme.of(context).cardColor,
                                child: Icon(Icons.remove_rounded, color: bk.textPrimary),
                                onPressed: () {
                                  _mapController.move(
                                    _mapController.camera.center,
                                    _mapController.camera.zoom - 1,
                                  );
                                },
                              ),
                              if (fullPolyline.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                FloatingActionButton.small(
                                  heroTag: 'fitBoundsBtn',
                                  backgroundColor: Theme.of(context).cardColor,
                                  child: Icon(Icons.center_focus_strong_rounded, color: bk.accent),
                                  onPressed: () => _fitMapToPoints(fullPolyline),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Bottom helper legend
                        Positioned(
                          bottom: 8,
                          left: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded, size: 14, color: Colors.blueAccent),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    isBangla
                                        ? 'মানচিত্রে ট্যাপ করে বা স্লাইডার টেনে পয়েন্ট ১ (A) এবং পয়েন্ট ২ (B) নির্ধারণ করুন'
                                        : 'Tap on map or drag slider to set Point A & Point B',
                                    style: text.bodySmall?.copyWith(fontSize: 11, color: bk.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Point Controls Bar
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.location_on_rounded, color: Colors.green, size: 18),
                        label: Text(
                          pA == null
                              ? (isBangla ? 'পয়েন্ট A সেট (ধানমন্ডি)' : 'Set Point A')
                              : 'A: ${pA.latitude.toStringAsFixed(3)}, ${pA.longitude.toStringAsFixed(3)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () {
                          setState(() {
                            // Default preset Dhanmondi if none set
                            _customPointA = const ll.LatLng(23.7461, 90.3742);
                          });
                          _mapController.move(_customPointA!, 14.0);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.flag_rounded, color: Colors.redAccent, size: 18),
                        label: Text(
                          pB == null
                              ? (isBangla ? 'পয়েন্ট B সেট (ফার্মগেট)' : 'Set Point B')
                              : 'B: ${pB.latitude.toStringAsFixed(3)}, ${pB.longitude.toStringAsFixed(3)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () {
                          setState(() {
                            // Default preset Farmgate if none set
                            _customPointB = const ll.LatLng(23.7561, 90.3872);
                          });
                          _mapController.move(_customPointB!, 14.0);
                        },
                      ),
                    ),
                  ],
                ),
                if (_customPointA != null || _customPointB != null) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(isBangla ? 'পয়েন্ট রিসেট' : 'Reset Points'),
                      onPressed: () {
                        setState(() {
                          _customPointA = null;
                          _customPointB = null;
                          if (hasRoutePoints) {
                            _indexA = 0;
                            _indexB = routePointCount - 1;
                          }
                        });
                      },
                    ),
                  ),
                ],
              ],
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
