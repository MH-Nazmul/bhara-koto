import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A dot that breathes while the meter is live, so a glance at the screen
/// answers "is this thing still counting?".
class LiveDot extends StatefulWidget {
  const LiveDot({super.key, required this.color, this.active = false, this.size = 7});

  final Color color;
  final bool active;
  final double size;

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant LiveDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    );

    if (!widget.active) return dot;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeOut.transform(_controller.value);
        return SizedBox(
          width: widget.size * 3,
          height: widget.size * 3,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: widget.size * (1 + 2 * t),
                height: widget.size * (1 + 2 * t),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.28 * (1 - t)),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: dot,
    );
  }
}

/// Compact state badge — the only place the app spells out what it is doing.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    required this.background,
    this.active = false,
    this.icon,
  });

  final String label;
  final Color color;
  final Color background;
  final bool active;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(active ? 4 : 9, 4, 10, 4),
      decoration: BoxDecoration(color: background, borderRadius: BkRadius.pill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Icon(icon, size: 12, color: color),
            )
          else
            LiveDot(color: color, active: active),
          SizedBox(width: active ? 2 : 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  letterSpacing: 0.3,
                ),
          ),
        ],
      ),
    );
  }
}

/// Borderless square icon button sized for a dense header row.
class CompactIconButton extends StatelessWidget {
  const CompactIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.highlighted = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final bk = context.bk;
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: highlighted ? bk.accentSoft : Colors.transparent,
        borderRadius: BkRadius.medium,
        child: InkWell(
          borderRadius: BkRadius.medium,
          onTap: onPressed,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, size: 19, color: highlighted ? bk.accent : bk.textSecondary),
          ),
        ),
      ),
    );
  }
}

/// Text-only variant used for the language switch, where "অ" / "A" reads faster
/// than any icon.
class CompactTextButton extends StatelessWidget {
  const CompactTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tooltip,
  });

  final String label;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final bk = context.bk;
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.transparent,
        borderRadius: BkRadius.medium,
        child: InkWell(
          borderRadius: BkRadius.medium,
          onTap: onPressed,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: bk.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
