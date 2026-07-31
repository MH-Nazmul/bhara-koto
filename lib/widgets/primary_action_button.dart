import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The single tap target that matters. Full-bleed and 58px tall so it can be
/// hit while holding a moving bus's handrail, but flat and pill-shaped rather
/// than a heavy slab.
class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.background,
    required this.foreground,
    this.outlined = false,
    this.busy = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final bool outlined;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: outlined ? Colors.transparent : background,
        borderRadius: BkRadius.large,
        child: InkWell(
          borderRadius: BkRadius.large,
          onTap: enabled ? onPressed : null,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BkRadius.large,
              border: outlined ? Border.all(color: background, width: 1.5) : null,
            ),
            child: SizedBox(
              height: 58,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (busy)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
                    )
                  else
                    Icon(icon, size: 20, color: foreground),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Quieter companion action ("Still moving", "New trip") that must not compete
/// with the primary button.
class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? context.bk.textSecondary;
    return Material(
      color: Colors.transparent,
      borderRadius: BkRadius.medium,
      child: InkWell(
        borderRadius: BkRadius.medium,
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: tint),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: tint,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
