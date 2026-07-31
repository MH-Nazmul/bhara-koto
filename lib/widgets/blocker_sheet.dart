import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import 'primary_action_button.dart';

/// Explains, in the user's language, exactly what is blocking the meter and
/// gives them the one button that fixes it.
Future<void> showBlockerSheet(
  BuildContext context,
  LocationReadiness readiness,
  LocationService service,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _BlockerSheet(readiness: readiness, service: service),
  );
}

class _BlockerSheet extends StatelessWidget {
  const _BlockerSheet({required this.readiness, required this.service});

  final LocationReadiness readiness;
  final LocationService service;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final bk = context.bk;
    final text = Theme.of(context).textTheme;

    final serviceOff = readiness == LocationReadiness.serviceDisabled;
    final blockedForever = readiness == LocationReadiness.deniedForever;

    final title = serviceOff ? t.serviceDisabledTitle : t.permissionTitle;
    final body = serviceOff
        ? t.serviceDisabledBody
        : blockedForever
            ? t.permissionDeniedForever
            : t.permissionBody;
    final actionLabel = serviceOff
        ? t.openLocationSettings
        : blockedForever
            ? t.openAppSettings
            : t.permissionGrant;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: bk.warningSoft, borderRadius: BkRadius.medium),
              child: Icon(
                serviceOff ? Icons.location_disabled_rounded : Icons.my_location_rounded,
                color: bk.warning,
                size: 20,
              ),
            ),
            const SizedBox(height: 14),
            Text(title, style: text.headlineSmall),
            const SizedBox(height: 6),
            Text(body, style: text.bodyMedium?.copyWith(color: bk.textSecondary)),
            const SizedBox(height: 20),
            PrimaryActionButton(
              label: actionLabel,
              icon: Icons.settings_rounded,
              background: bk.accent,
              foreground: Theme.of(context).colorScheme.onPrimary,
              onPressed: () async {
                Navigator.of(context).pop();
                if (serviceOff) {
                  await service.openLocationSettings();
                } else if (blockedForever) {
                  await service.openAppSettings();
                }
                // A plain "denied" needs no navigation — the next Start tap
                // re-triggers the system prompt.
              },
            ),
            const SizedBox(height: 4),
            Center(child: GhostButton(label: t.close, onPressed: () => Navigator.of(context).pop())),
          ],
        ),
      ),
    );
  }
}
