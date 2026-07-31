import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The one container used across the app: a flat surface held by a hairline.
///
/// No drop shadows anywhere — shadows go grey and muddy in sunlight, while a
/// 1px border keeps its edge at any brightness.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.borderColor,
    this.background,
    this.radius = BkRadius.large,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Color? background;
  final BorderRadius radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bk = context.bk;
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: padding,
      decoration: BoxDecoration(
        color: background ?? bk.surface,
        borderRadius: radius,
        border: Border.all(color: borderColor ?? bk.hairline),
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: radius, onTap: onTap, child: content),
    );
  }
}

/// Small caps-ish label that opens a group of settings.
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: context.bk.textFaint,
            ),
      ),
    );
  }
}
