import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models/fare_config.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/notice_banner.dart';
import '../widgets/segmented_control.dart';
import '../widgets/surface_card.dart';
import 'home_screen.dart' show sourceBadge, profileLabel, profileHint;

/// Everything that isn't the meter: both fare tables, where they come from, and
/// the two appearance switches. Same visual language as home — hairline cards,
/// tight rows, no filler.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context).app;
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.settings)),
      body: ListenableBuilder(
        listenable: app,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            SectionHeading(t.sectionFare),
            _RatesCard(app: app),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                t.editRatesHint,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: context.bk.textFaint, fontSize: 11.5),
              ),
            ),
            if (app.manualEnabled) ...[
              const SizedBox(height: 10),
              NoticeBanner(
                icon: Icons.edit_note_rounded,
                title: t.manualBannerTitle,
                message: t.manualBannerBody,
                tint: context.bk.warning,
                background: context.bk.warningSoft,
              ),
              const SizedBox(height: 8),
              _ActionTile(
                icon: Icons.cloud_download_rounded,
                title: t.useServerRates,
                onTap: app.useServerRates,
              ),
            ],

            SectionHeading(t.sectionAppearance),
            _SettingRow(
              label: t.language,
              control: SegmentedControl(
                options: [t.themeSystem, t.languageEnglish, t.languageBangla],
                selectedIndex: switch (app.languageCode) {
                  'en' => 1,
                  'bn' => 2,
                  _ => 0,
                },
                onChanged: (index) => app.setLanguage(switch (index) {
                  1 => 'en',
                  2 => 'bn',
                  _ => null,
                }),
              ),
            ),
            const SizedBox(height: 8),
            _SettingRow(
              label: t.theme,
              control: SegmentedControl(
                options: [t.themeSystem, t.themeLight, t.themeDark],
                selectedIndex: switch (app.themeMode) {
                  ThemeMode.light => 1,
                  ThemeMode.dark => 2,
                  ThemeMode.system => 0,
                },
                onChanged: (index) => app.setThemeMode(switch (index) {
                  1 => ThemeMode.light,
                  2 => ThemeMode.dark,
                  _ => ThemeMode.system,
                }),
              ),
            ),

            SectionHeading(t.sectionAbout),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.appName, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    t.version(
                      Fmt.digits(kAppVersion, Localizations.localeOf(context).languageCode),
                    ),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: context.bk.textFaint),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    t.disclaimer,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: context.bk.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ rates ---

/// Both fare tables at once, with the one currently in force marked. Tapping a
/// row overrides just that profile.
class _RatesCard extends StatelessWidget {
  const _RatesCard({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final bk = context.bk;
    final badge = sourceBadge(t, bk, app.source);

    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Column(
        children: [
          for (final profile in FareProfile.values) ...[
            _RateRow(
              profile: profile,
              app: app,
              active: profile == app.profile,
            ),
            if (profile != FareProfile.values.last)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Divider(height: 1, color: bk.hairline),
              ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
            child: Column(
              children: [
                Divider(height: 1, color: bk.hairline),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: badge.$2, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        badge.$1,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: bk.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    Text(
                      _lastSyncedLabel(context, app),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: bk.textFaint, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _lastSyncedLabel(BuildContext context, AppState app) {
    final t = AppLocalizations.of(context);
    final at = app.lastSyncedAt;
    if (at == null) return t.neverSynced;

    final ml = MaterialLocalizations.of(context);
    final stamp = '${ml.formatShortDate(at)}, ${ml.formatTimeOfDay(TimeOfDay.fromDateTime(at))}';
    return t.lastSynced(stamp);
  }
}

class _RateRow extends StatelessWidget {
  const _RateRow({required this.profile, required this.app, required this.active});

  final FareProfile profile;
  final AppState app;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final bk = context.bk;
    final lang = Localizations.localeOf(context).languageCode;
    final rate = app.config.rateFor(profile);

    return Material(
      color: Colors.transparent,
      borderRadius: BkRadius.medium,
      child: InkWell(
        borderRadius: BkRadius.medium,
        onTap: () => _showRateEditor(context, app, profile),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 11, 10, 11),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          profileLabel(t, profile),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (active) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: bk.accentSoft,
                              borderRadius: BkRadius.pill,
                            ),
                            child: Text(
                              t.inUse,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: bk.accent,
                                    fontSize: 9.5,
                                    letterSpacing: 0.2,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      profileHint(t, profile),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: bk.textFaint, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${t.unitTaka}${Fmt.rate(rate.ratePerKm, lang)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 19),
                  ),
                  Text(
                    '${t.labelMinFare} ${t.unitTaka}${Fmt.rate(rate.minFare, lang)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: bk.textFaint, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              Icon(Icons.edit_rounded, size: 15, color: bk.textFaint),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- primitives ---

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bk = context.bk;
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: bk.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 18, color: bk.textFaint),
        ],
      ),
    );
  }
}

/// A label on the left, a control on the right — cheaper on vertical space than
/// stacking a title above a full-width widget.
class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.control});

  final String label;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 11, 11, 11),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
          control,
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- editors ---

/// Overrides one profile's numbers. The other profile is untouched, so fixing
/// the long-distance rate never disturbs the local one.
Future<void> _showRateEditor(BuildContext context, AppState app, FareProfile profile) async {
  final t = AppLocalizations.of(context);
  final formKey = GlobalKey<FormState>();
  final current = app.config.rateFor(profile);
  final rateController = TextEditingController(text: current.ratePerKm.toString());
  final minController = TextEditingController(text: current.minFare.toString());

  String? validate(String? raw, {bool allowZero = false}) {
    final value = double.tryParse((raw ?? '').trim());
    if (value == null || value.isNaN || (allowZero ? value < 0 : value <= 0)) {
      return t.invalidNumber;
    }
    return null;
  }

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(t.editRatesFor(profileLabel(t, profile))),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: rateController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: InputDecoration(
                labelText: t.fieldRatePerKm,
                prefixText: '${t.unitTaka} ',
              ),
              validator: (value) => validate(value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: minController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: InputDecoration(
                labelText: t.fieldMinFare,
                prefixText: '${t.unitTaka} ',
              ),
              validator: (value) => validate(value, allowZero: true),
            ),
            const SizedBox(height: 10),
            Text(
              t.editRatesHint,
              style: Theme.of(dialogContext)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: dialogContext.bk.textFaint, fontSize: 11.5),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(t.cancel),
        ),
        TextButton(
          onPressed: () {
            if (!(formKey.currentState?.validate() ?? false)) return;
            app.saveManualRate(
              profile,
              FareRate(
                ratePerKm: double.parse(rateController.text.trim()),
                minFare: double.parse(minController.text.trim()),
              ),
            );
            Navigator.of(dialogContext).pop();
          },
          child: Text(t.save),
        ),
      ],
    ),
  );

  rateController.dispose();
  minController.dispose();
}
