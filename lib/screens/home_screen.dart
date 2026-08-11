import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/fare_config.dart';
import '../models/trip_history_model.dart';
import '../services/location_service.dart';
import '../services/overlay_service.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../state/trip_state.dart';
import '../theme/app_theme.dart';
import '../utils/calculator.dart';
import '../utils/formatters.dart';
import '../widgets/blocker_sheet.dart';
import '../widgets/fare_hero.dart';
import '../widgets/fare_receipt_dialog.dart';
import '../widgets/metric_row.dart';
import '../widgets/notice_banner.dart';
import '../widgets/primary_action_button.dart';
import '../widgets/rate_strip.dart';
import '../widgets/segmented_control.dart';
import '../widgets/speedometer_widget.dart';
import '../widgets/status_pill.dart';
import 'bus_routes_screen.dart';
import 'history_screen.dart';
import 'overcharge_screen.dart';
import 'settings_screen.dart';

/// One screen, no scrolling: dense chrome at the edges and a fare that owns the
/// middle. Every row is sized so the layout holds from a small 5" phone up to a
/// tablet without leaving a lake of empty space.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.locationService});

  final LocationService locationService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _popupShown = false;
  bool _initializedPermissions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestFirstLaunchPermissions();
      _setupNativeOverlayListener();
    });
  }

  void _setupNativeOverlayListener() {
    final scope = AppScope.of(context);
    OverlayService.listenNativeOverlayEvents(
      onStartTrip: () async {
        final t = AppLocalizations.of(context);
        await scope.trip.start(
          notificationTitle: t.appName,
          notificationText: t.statusTracking,
        );
      },
      onStopTrip: () async {
        await scope.trip.stop();
      },
    );
  }

  Future<void> _requestFirstLaunchPermissions() async {
    if (_initializedPermissions) return;
    _initializedPermissions = true;

    // 1. Request standard Location permission automatically on first launch
    final readiness = await widget.locationService.ensureReady();
    if (readiness == LocationReadiness.ready && mounted) {
      final app = AppScope.of(context).app;
      final lang = app.languageCode ?? Localizations.localeOf(context).languageCode;
      AppScope.of(context).trip.startStandbyMonitoring();
      OverlayService.startNativeMotionMonitoring(app.config.detectVehicleSpeedKmh, lang);
    }

    // 2. Check if Display over other apps (Overlay) is granted; if not, prompt user directly
    final overlayGranted = await OverlayService.checkOverlayPermission();
    if (!overlayGranted && mounted) {
      final isBangla = Localizations.localeOf(context).languageCode == 'bn';
      showDialog<void>(
        context: context,
        builder: (ctx) {
          final bk = ctx.bk;
          final text = Theme.of(ctx).textTheme;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.layers_rounded, color: bk.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isBangla ? 'পপ-আপ মিটার পারমিশন' : 'Display Over Apps Permission',
                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Text(
              isBangla
                  ? 'যানবাহনে ওঠার সাথে সাথে স্বয়ংক্রিয় পপ-আপ মিটার দেখতে "Display over other apps" পারমিশন এনাবল করুন।'
                  : 'To enable automatic floating meter pop-ups when entering a vehicle, please allow "Display over other apps" permission.',
              style: text.bodyMedium?.copyWith(color: bk.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(isBangla ? 'পরে করুন' : 'Later'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: bk.accent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await OverlayService.requestOverlayPermission();
                },
                child: Text(isBangla ? 'অন করুন' : 'Enable Now'),
              ),
            ],
          );
        },
      );
    }
  }

  void _checkMotionDetection(AppState app, TripState trip) {
    if (_popupShown || trip.phase != TripPhase.idle) return;
    final currentSpeedKmh = trip.speedMps * 3.6;
    final thresholdKmh = app.config.detectVehicleSpeedKmh;

    if (currentSpeedKmh >= thresholdKmh && currentSpeedKmh > 0) {
      _popupShown = true;
      final t = AppLocalizations.of(context);
      final lang = app.languageCode ?? Localizations.localeOf(context).languageCode;
      final isBangla = lang == 'bn';

      // 1. Trigger Heads-Up High Priority Notification
      OverlayService.showNotification(
        title: isBangla ? '🚌 যানবাহনে গতির শনাক্তকরণ!' : '🚌 Vehicle Movement Detected!',
        body: isBangla
            ? 'আপনার বর্তমান গতি: ${currentSpeedKmh.toStringAsFixed(1)} km/h। স্পর্শ করে ভাড়া গণনা শুরু করুন।'
            : 'Speed: ${currentSpeedKmh.toStringAsFixed(1)} km/h. Tap to start fare meter.',
        lang: lang,
      );

      // 2. Show in-app dialog if app is in foreground
      OverlayService.showFloatingPopup(
        context: context,
        currentSpeedKmh: currentSpeedKmh,
        thresholdKmh: thresholdKmh,
        onStartJourneyPressed: () async {
          await trip.start(
            notificationTitle: t.appName,
            notificationText: t.statusTracking,
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = AppLocalizations.of(context);
    final bk = context.bk;

    _checkMotionDetection(scope.app, scope.trip);

    if (scope.trip.isActive) {
      final fare = FareCalculator.compute(
        distanceMeters: scope.trip.distanceMeters,
        rate: scope.app.activeRate,
      );
      final lang = scope.app.languageCode ?? Localizations.localeOf(context).languageCode;
      OverlayService.updateNativeMeterOverlay(
        fareTotal: '৳ ${Fmt.money(fare.total, lang)}',
        distanceKm: Fmt.distanceKm(scope.trip.distanceMeters, lang),
        speedKmh: Fmt.speedKmh(scope.trip.speedMps, lang),
        lang: lang,
      );
    } else {
      OverlayService.dismissNativeOverlay();
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(app: scope.app),
              const SizedBox(height: 8),
              // Which bus you're on decides which rate applies, so it sits
              // above the rate it produces.
              ListenableBuilder(
                listenable: scope.app,
                builder: (context, _) => _ProfilePicker(app: scope.app),
              ),
              const SizedBox(height: 8),
              ListenableBuilder(
                listenable: scope.app,
                builder: (context, _) => _RateStripSection(app: scope.app),
              ),
              const SizedBox(height: 8),
              // The hero takes every pixel the fixed rows don't need.
              Expanded(
                child: ListenableBuilder(
                  listenable: Listenable.merge([scope.app, scope.trip]),
                  builder: (context, _) => _Meter(app: scope.app, trip: scope.trip),
                ),
              ),
              const SizedBox(height: 10),
              ListenableBuilder(
                listenable: Listenable.merge([scope.app, scope.trip]),
                builder: (context, _) => _BannerSlot(app: scope.app, trip: scope.trip),
              ),
              ListenableBuilder(
                listenable: scope.trip,
                builder: (context, _) => _ActionBar(
                  trip: scope.trip,
                  locationService: widget.locationService,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t.disclaimer,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: bk.textFaint, fontSize: 10.5, height: 1.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- header ---

class _Header extends StatelessWidget {
  const _Header({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final bk = context.bk;
    final isBangla = Localizations.localeOf(context).languageCode == 'bn';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 42,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  t.appName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                Text(
                  t.appTagline,
                  style: TextStyle(fontSize: 10.5, color: bk.textFaint, height: 1.2),
                ),
              ],
            ),
          ),
          // Language and theme are one tap away because the app is used by two
          // very different readerships on the same bus.
          CompactTextButton(
            label: isBangla ? 'A' : 'অ',
            tooltip: t.language,
            onPressed: () => app.setLanguage(isBangla ? 'en' : 'bn'),
          ),
          CompactIconButton(
            icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            tooltip: t.theme,
            onPressed: () => app.setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark),
          ),
          CompactIconButton(
            icon: Icons.history_rounded,
            tooltip: isBangla ? 'ভ্রমণ ইতিহাস' : 'History',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => HistoryScreen(
                  storage: AppScope.of(context).app.storage,
                  config: app.config,
                  profile: app.profile,
                ),
              ),
            ),
          ),
          CompactIconButton(
            icon: Icons.alt_route_rounded,
            tooltip: isBangla ? 'বাস রুট চাট' : 'Bus Routes',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => BusRoutesScreen(config: app.config),
              ),
            ),
          ),
          if (app.enableOverchargeReporting)
            CompactIconButton(
              icon: Icons.report_problem_rounded,
              tooltip: isBangla ? 'ভাড়ার অভিযোগ' : 'Overcharge Reports',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => OverchargeScreen(storage: AppScope.of(context).app.storage),
                ),
              ),
            ),
          CompactIconButton(
            icon: Icons.tune_rounded,
            tooltip: t.settings,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- profile ---

class _ProfilePicker extends StatelessWidget {
  const _ProfilePicker({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return SegmentedControl(
      expand: true,
      options: [profileLabel(t, FareProfile.local), profileLabel(t, FareProfile.intercity)],
      selectedIndex: app.profile == FareProfile.intercity ? 1 : 0,
      // Switching mid-trip is allowed on purpose: passengers realise they got
      // it wrong, and the fare simply recomputes from the distance so far.
      onChanged: (index) =>
          app.setProfile(index == 1 ? FareProfile.intercity : FareProfile.local),
    );
  }
}

String profileLabel(AppLocalizations t, FareProfile profile) => switch (profile) {
      FareProfile.local => t.profileLocal,
      FareProfile.intercity => t.profileIntercity,
    };

String profileHint(AppLocalizations t, FareProfile profile) => switch (profile) {
      FareProfile.local => t.profileLocalHint,
      FareProfile.intercity => t.profileIntercityHint,
    };

// ------------------------------------------------------------ rate strip ---

class _RateStripSection extends StatelessWidget {
  const _RateStripSection({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final bk = context.bk;
    final lang = Localizations.localeOf(context).languageCode;
    final rate = app.activeRate;
    final badge = sourceBadge(t, bk, app.source);

    return RateStrip(
      rateLabel: '${t.unitTaka}${Fmt.rate(rate.ratePerKm, lang)} / ${t.unitKm}',
      minLabel: '${t.labelMinFare} ${t.unitTaka}${Fmt.rate(rate.minFare, lang)}',
      sourceLabel: badge.$1,
      sourceColor: badge.$2,
      syncing: app.syncStatus == SyncStatus.syncing,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
      ),
    );
  }
}

/// Shared by the home strip and the settings screen so "where do these numbers
/// come from" is answered identically in both places.
(String, Color) sourceBadge(AppLocalizations t, BkColors bk, FareSource source) =>
    switch (source) {
      FareSource.remote => (t.sourceRemote, bk.accent),
      FareSource.cached => (t.sourceCached, bk.textFaint),
      FareSource.manual => (t.sourceManual, bk.warning),
      FareSource.fallback => (t.sourceDefault, bk.textFaint),
    };

// ----------------------------------------------------------------- meter ---

class _Meter extends StatelessWidget {
  const _Meter({required this.app, required this.trip});

  final AppState app;
  final TripState trip;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final bk = context.bk;
    final lang = Localizations.localeOf(context).languageCode;

    final fare = FareCalculator.compute(
      distanceMeters: trip.distanceMeters,
      rate: app.activeRate,
    );

    final isIdle = trip.phase == TripPhase.idle;
    final highlight = trip.phase == TripPhase.stopped;

    // After the trip ends the average speed is the useful reading; while it
    // runs, the live one is.
    final speedMps = trip.phase == TripPhase.finished && trip.elapsed.inSeconds > 0
        ? trip.distanceMeters / trip.elapsed.inSeconds
        : trip.speedMps;

    final String caption;
    final Color? captionColor;
    if (isIdle) {
      caption = t.startHint;
      captionColor = null;
    } else if (fare.minimumApplied) {
      caption = t.minFareApplied;
      captionColor = bk.warning;
    } else {
      caption = t.fareBreakdown(
        Fmt.distanceKm(trip.distanceMeters, lang),
        Fmt.rate(fare.ratePerKm, lang),
      );
      captionColor = null;
    }

    // The ring fills once per kilometre, which is exactly the cadence at which
    // the fare steps up.
    final km = trip.distanceMeters / 1000;
    final isBangla = lang == 'bn';

    return Column(
      children: [
        if (trip.isActive) SpeedometerWidget(speedMps: speedMps),
        Expanded(
          child: FareHero(
            statusPill: _statusPill(context, trip.phase),
            trailing: trip.isActive
                ? _AccuracyChip(trip: trip)
                : (trip.phase == TripPhase.finished
                    ? TextButton.icon(
                        icon: const Icon(Icons.receipt_rounded, size: 16),
                        label: Text(isBangla ? 'রসিদ' : 'Receipt'),
                        onPressed: () {
                          showDialog<void>(
                            context: context,
                            builder: (_) => FareReceiptDialog(
                              distanceMeters: trip.distanceMeters,
                              fareProfile: app.profile,
                              ratePerKm: app.activeRate.ratePerKm,
                              minFare: app.activeRate.minFare,
                              startedAt: trip.startedAt ?? DateTime.now(),
                              endedAt: trip.endedAt ?? DateTime.now(),
                              onReportOverchargePressed: app.enableOverchargeReporting
                                  ? () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => OverchargeScreen(storage: app.storage),
                                        ),
                                      );
                                    }
                                  : null,
                            ),
                          );
                        },
                      )
                    : null),
            dialProgress: km - km.floorToDouble(),
            currency: t.unitTaka,
            amount: Fmt.money(isIdle ? 0 : fare.total, lang),
            meteredAmount: isIdle ? null : Fmt.money(fare.metered, lang),
            isMinimumApplied: !isIdle && fare.minimumApplied,
            caption: caption,
            captionColor: captionColor,
            highlight: highlight,
            dimmed: isIdle,
            metrics: MetricRow(
              cells: [
                MetricCell(
                  label: t.labelDistance,
                  value: Fmt.distanceKm(trip.distanceMeters, lang),
                  unit: t.unitKm,
                  emphasis: trip.phase == TripPhase.running,
                ),
                MetricCell(
                  label: t.labelDuration,
                  value: Fmt.duration(trip.elapsed, lang),
                ),
                MetricCell(
                  label: t.labelSpeed,
                  value: Fmt.speedKmh(speedMps, lang),
                  unit: t.unitKmh,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusPill(BuildContext context, TripPhase phase) {
    final t = AppLocalizations.of(context);
    final bk = context.bk;

    return switch (phase) {
      TripPhase.idle => StatusPill(
          label: t.statusIdle,
          color: bk.textSecondary,
          background: bk.surfaceRaised,
          icon: Icons.circle_outlined,
        ),
      TripPhase.acquiring => StatusPill(
          label: t.statusLocking,
          color: bk.warning,
          background: bk.warningSoft,
          active: true,
        ),
      TripPhase.running => StatusPill(
          label: t.statusTracking,
          color: bk.accent,
          background: bk.accentSoft,
          active: true,
        ),
      TripPhase.stopped => StatusPill(
          label: t.statusPaused,
          color: bk.warning,
          background: bk.warningSoft,
          icon: Icons.pause_rounded,
        ),
      TripPhase.finished => StatusPill(
          label: t.statusFinished,
          color: bk.accent,
          background: bk.accentSoft,
          icon: Icons.check_rounded,
        ),
    };
  }
}

/// GPS precision, shown only while tracking — it turns amber when the fix is
/// loose enough to distort the distance.
class _AccuracyChip extends StatelessWidget {
  const _AccuracyChip({required this.trip});

  final TripState trip;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final bk = context.bk;
    final lang = Localizations.localeOf(context).languageCode;
    final accuracy = trip.accuracyMeters;
    if (accuracy == null) return const SizedBox.shrink();

    final weak = trip.weakSignal;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          weak ? Icons.signal_cellular_alt_1_bar_rounded : Icons.gps_fixed_rounded,
          size: 12,
          color: weak ? bk.warning : bk.textFaint,
        ),
        const SizedBox(width: 4),
        Text(
          t.accuracyMeters(Fmt.digits(accuracy.round().toString(), lang)),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: weak ? bk.warning : bk.textFaint,
                letterSpacing: 0,
              ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- banner ---

class _BannerSlot extends StatelessWidget {
  const _BannerSlot({required this.app, required this.trip});

  final AppState app;
  final TripState trip;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final bk = context.bk;
    final lang = Localizations.localeOf(context).languageCode;

    Widget? banner;

    if (trip.phase == TripPhase.stopped) {
      // The blueprint's key moment: movement has ceased, so the fare stops
      // being a running total and becomes the answer.
      banner = NoticeBanner(
        icon: Icons.flag_rounded,
        title: t.arrivedTitle,
        message: t.arrivedBody,
        tint: bk.accent,
        background: bk.accentSoft,
        action: GhostButton(
          label: t.stillMoving,
          color: bk.accent,
          onPressed: trip.dismissStopDetection,
        ),
      );
    } else if (trip.weakSignal) {
      banner = NoticeBanner(
        icon: Icons.warning_amber_rounded,
        title: t.weakSignal,
        tint: bk.warning,
        background: bk.warningSoft,
      );
    } else if (!trip.isActive && app.config.noticeFor(lang) != null) {
      banner = NoticeBanner(
        icon: Icons.campaign_rounded,
        title: app.config.noticeFor(lang)!,
        tint: bk.textSecondary,
        background: bk.surfaceRaised,
      );
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: banner == null
          ? const SizedBox(width: double.infinity)
          : Padding(padding: const EdgeInsets.only(bottom: 10), child: banner),
    );
  }
}

// ------------------------------------------------------------- action bar ---

class _ActionBar extends StatefulWidget {
  const _ActionBar({required this.trip, required this.locationService});

  final TripState trip;
  final LocationService locationService;

  @override
  State<_ActionBar> createState() => _ActionBarState();
}

class _ActionBarState extends State<_ActionBar> {
  bool _starting = false;

  Future<void> _start() async {
    final t = AppLocalizations.of(context);
    setState(() => _starting = true);

    await widget.trip.start(
      notificationTitle: t.appName,
      notificationText: t.statusTracking,
    );

    if (!mounted) return;
    setState(() => _starting = false);

    // A refused permission surfaces as a sheet rather than a silent no-op.
    final blocker = widget.trip.blocker;
    if (blocker != null) {
      widget.trip.clearBlocker();
      await showBlockerSheet(context, blocker, widget.locationService);
    }
  }

  Future<void> _stop() async {
    final scope = AppScope.of(context);
    final breakdown = FareCalculator.compute(
      distanceMeters: widget.trip.distanceMeters,
      rate: scope.app.activeRate,
    );

    final item = TripHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startedAt: widget.trip.startedAt ?? DateTime.now(),
      endedAt: DateTime.now(),
      distanceMeters: widget.trip.distanceMeters,
      fareTotal: breakdown.total,
      profile: scope.app.profile,
      routePoints: widget.trip.routePoints,
    );

    await scope.app.storage.addTripHistoryItem(item);
    await widget.trip.stop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final bk = context.bk;
    final scheme = Theme.of(context).colorScheme;
    final trip = widget.trip;

    return switch (trip.phase) {
      TripPhase.idle => PrimaryActionButton(
          label: t.startJourney,
          icon: Icons.play_arrow_rounded,
          background: bk.accent,
          foreground: scheme.onPrimary,
          busy: _starting,
          onPressed: _start,
        ),
      TripPhase.finished => PrimaryActionButton(
          label: t.newTrip,
          icon: Icons.refresh_rounded,
          background: bk.accent,
          foreground: bk.accent,
          outlined: true,
          onPressed: trip.reset,
        ),
      _ => PrimaryActionButton(
          label: t.endJourney,
          icon: Icons.stop_rounded,
          background: bk.danger,
          foreground: Colors.white,
          onPressed: _stop,
        ),
    };
  }
}
