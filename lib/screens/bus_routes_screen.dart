import 'package:flutter/material.dart';

import '../models/bus_route_model.dart';
import '../models/fare_config.dart';
import '../theme/app_theme.dart';
import '../utils/calculator.dart';
import '../utils/formatters.dart';
import '../widgets/surface_card.dart';

class BusRoutesScreen extends StatefulWidget {
  const BusRoutesScreen({
    super.key,
    required this.config,
  });

  final FareConfig config;

  @override
  State<BusRoutesScreen> createState() => _BusRoutesScreenState();
}

class _BusRoutesScreenState extends State<BusRoutesScreen> {
  late BusRoute _selectedRoute;
  late BusStop _originStop;
  late BusStop _destinationStop;
  FareProfile _profile = FareProfile.local;

  @override
  void initState() {
    super.initState();
    _selectedRoute = BusRoute.presetRoutes.first;
    _originStop = _selectedRoute.stops.first;
    _destinationStop = _selectedRoute.stops.last;
  }

  void _onRouteChanged(BusRoute route) {
    setState(() {
      _selectedRoute = route;
      _originStop = route.stops.first;
      _destinationStop = route.stops.last;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bk = context.bk;
    final text = Theme.of(context).textTheme;
    final isBangla = Localizations.localeOf(context).languageCode == 'bn';
    final lang = isBangla ? 'bn' : 'en';

    final distanceKm = (_destinationStop.kmFromStart - _originStop.kmFromStart).abs();
    final distanceMeters = distanceKm * 1000;

    final rate = widget.config.rateFor(_profile);
    final breakdown = FareCalculator.compute(
      distanceMeters: distanceMeters,
      rate: rate,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isBangla ? 'বাস রুট ও স্টপ ভিত্তিক ভাড়া' : 'Bus Routes & Stop Fares',
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Route selector
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isBangla ? 'বাস রুট নির্বাচন করুন:' : 'Select Bus Route:',
                    style: text.bodySmall?.copyWith(color: bk.textFaint, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<BusRoute>(
                    value: _selectedRoute,
                    isExpanded: true,
                    decoration: const InputDecoration(isDense: true),
                    items: BusRoute.presetRoutes
                        .map(
                          (route) => DropdownMenuItem(
                            value: route,
                            child: Text(
                              isBangla ? route.nameBn : route.nameEn,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) _onRouteChanged(val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Origin & Destination Pickers
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
                              isBangla ? 'যাত্রার স্থান (উঠা):' : 'Start Stop:',
                              style: text.bodySmall?.copyWith(color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<BusStop>(
                              value: _originStop,
                              isExpanded: true,
                              decoration: const InputDecoration(isDense: true),
                              items: _selectedRoute.stops
                                  .map(
                                    (stop) => DropdownMenuItem(
                                      value: stop,
                                      child: Text(
                                        isBangla ? stop.nameBn : stop.nameEn,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _originStop = val);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isBangla ? 'গন্তব্য স্থান (নামা):' : 'End Stop:',
                              style: text.bodySmall?.copyWith(color: Colors.redAccent, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<BusStop>(
                              value: _destinationStop,
                              isExpanded: true,
                              decoration: const InputDecoration(isDense: true),
                              items: _selectedRoute.stops
                                  .map(
                                    (stop) => DropdownMenuItem(
                                      value: stop,
                                      child: Text(
                                        isBangla ? stop.nameBn : stop.nameEn,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _destinationStop = val);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Fare Result Surface
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isBangla ? 'বিআরটিএ স্টপ ভাড়া' : 'BRTA Fare Result',
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
                        selected: {_profile},
                        onSelectionChanged: (s) {
                          setState(() => _profile = s.first);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isBangla ? 'নির্ধারিত দূরত্ব' : 'Distance',
                            style: text.bodySmall?.copyWith(color: bk.textFaint),
                          ),
                          Text(
                            '${Fmt.distanceKm(distanceMeters, lang)} km',
                            style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isBangla ? 'সরকারী ভাড়া' : 'Official Fare',
                            style: text.bodySmall?.copyWith(color: bk.textFaint),
                          ),
                          Row(
                            children: [
                              if (breakdown.minimumApplied) ...[
                                Text(
                                  '৳${Fmt.money(breakdown.metered, lang)}',
                                  style: text.titleSmall?.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: Colors.redAccent,
                                    color: bk.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_forward_rounded, size: 16, color: bk.warning),
                                const SizedBox(width: 4),
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
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Route Stop Timeline Visualizer
            Text(
              isBangla ? 'রুটের সমস্ত বাস স্টপসমূহ:' : 'All Stops on Route:',
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _selectedRoute.stops.length,
              itemBuilder: (context, index) {
                final stop = _selectedRoute.stops[index];
                final isStart = stop == _originStop;
                final isEnd = stop == _destinationStop;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isStart
                        ? bk.accentSoft
                        : isEnd
                            ? bk.dangerSoft
                            : bk.surfaceRaised,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isStart
                          ? bk.accent
                          : isEnd
                              ? bk.danger
                              : bk.hairline,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isStart
                            ? Icons.my_location_rounded
                            : isEnd
                                ? Icons.flag_rounded
                                : Icons.circle_outlined,
                        size: 18,
                        color: isStart
                            ? Colors.green
                            : isEnd
                                ? Colors.redAccent
                                : bk.textFaint,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isBangla ? stop.nameBn : stop.nameEn,
                          style: text.bodyMedium?.copyWith(
                            fontWeight: (isStart || isEnd) ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      Text(
                        '${stop.kmFromStart.toStringAsFixed(1)} km',
                        style: text.bodySmall?.copyWith(color: bk.textFaint),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
