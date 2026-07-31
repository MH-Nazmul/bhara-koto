import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Compact inline switcher. Every option is visible at once, which beats a
/// dropdown for a two-way choice the user makes while boarding a bus.
///
/// [expand] fills the available width (home screen); leaving it false keeps the
/// control intrinsic so it can sit at the end of a settings row.
class SegmentedControl extends StatelessWidget {
  const SegmentedControl({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
    this.expand = false,
  });

  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final bk = context.bk;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final segments = <Widget>[
      for (var i = 0; i < options.length; i++)
        _Segment(
          label: options[i],
          selected: i == selectedIndex,
          expand: expand,
          onTap: () => onChanged(i),
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? bk.canvas : const Color(0xFFEBEEF2),
        borderRadius: BkRadius.medium,
        border: Border.all(color: bk.hairline),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          for (final segment in segments)
            if (expand) Expanded(child: segment) else segment,
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.expand,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool expand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bk = context.bk;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: expand ? 8 : 11, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? bk.surface : Colors.transparent,
          borderRadius: BkRadius.small,
          border: Border.all(color: selected ? bk.hairline : Colors.transparent),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? bk.textPrimary : bk.textFaint,
          ),
        ),
      ),
    );
  }
}
