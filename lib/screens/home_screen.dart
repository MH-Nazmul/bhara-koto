import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/fare_config.dart';
import '../services/location_service.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../state/trip_state.dart';
import '../theme/app_theme.dart';
import '../utils/calculator.dart';
import '../utils/formatters.dart';
import '../widgets/blocker_sheet.dart';
import '../widgets/fare_hero.dart';
import '../widgets/metric_row.dart';
import '../widgets/notice_banner.dart';
import '../widgets/primary_action_button.dart';
import '../widgets/rate_strip.dart';
import '../widgets/segmented_control.dart';
import '../widgets/status_pill.dart';
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
  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = AppLocalizations.of(context);
    final bk = context.bk;

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

    return FareHero(
      statusPill: _statusPill(context, trip.phase),
      trailing: trip.isActive ? _AccuracyChip(trip: trip) : null,
      dialProgress: km - km.floorToDouble(),
      currency: t.unitTaka,
      amount: Fmt.money(isIdle ? 0 : fare.total, lang),
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
          onPressed: trip.stop,
        ),
    };
  }
}
