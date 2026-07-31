import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Low-profile inline message: a tinted strip with an icon, a line of text and
/// an optional action. Used for the stop-detected prompt, manual-rate warnings
/// and Gist notices, so all three read as the same kind of interruption.
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.tint,
    required this.background,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Color tint;
  final Color background;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final bk = context.bk;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, action == null ? 12 : 6, 10),
      decoration: BoxDecoration(color: background, borderRadius: BkRadius.medium),
      child: Row(
        children: [
          Icon(icon, size: 16, color: tint),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: text.bodySmall?.copyWith(
                    color: bk.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    message!,
                    style: text.bodySmall?.copyWith(color: bk.textSecondary, fontSize: 11.5),
                  ),
                ],
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}
