import 'package:flutter/material.dart';

/// Fades and slides its child in once, optionally after [delay].
/// Use [FadeSlideIn.staggered] to cascade items in a list or grid.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
    this.offset = const Offset(0, 24),
  });

  /// Delay grows with [index] (capped) for a cascading entrance.
  FadeSlideIn.staggered({
    super.key,
    required this.child,
    required int index,
    this.duration = const Duration(milliseconds: 500),
    this.offset = const Offset(0, 24),
  }) : delay = Duration(milliseconds: 70 * index.clamp(0, 12));

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _curve =
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: widget.offset * (1 - _curve.value),
          child: child,
        ),
      ),
    );
  }
}

/// Animates the first number found in [value] from 0 (e.g. "1,250", "₱12,400.50").
/// Non-numeric text is shown as-is.
class CountUpText extends StatelessWidget {
  const CountUpText({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 1100),
  });

  final String value;
  final TextStyle? style;
  final Duration duration;

  static final _number = RegExp(r'\d[\d,]*(\.\d+)?');

  static String _group(String digits) => digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

  @override
  Widget build(BuildContext context) {
    final match = _number.firstMatch(value);
    if (match == null) return Text(value, style: style);

    final raw = match.group(0)!;
    final target = double.tryParse(raw.replaceAll(',', ''));
    if (target == null) return Text(value, style: style);
    final decimals = raw.contains('.') ? raw.split('.').last.length : 0;
    final grouped = raw.contains(',');
    final prefix = value.substring(0, match.start);
    final suffix = value.substring(match.end);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        var s = v.toStringAsFixed(decimals);
        if (grouped) {
          final parts = s.split('.');
          s = _group(parts.first) + (parts.length > 1 ? '.${parts[1]}' : '');
        }
        return Text('$prefix$s$suffix', style: style);
      },
    );
  }
}

/// Gently pulses its child to draw attention (e.g. low-stock alerts).
class Pulse extends StatefulWidget {
  const Pulse({super.key, required this.child});
  final Widget child;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
        scale: Tween(begin: 1.0, end: 1.18)
            .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
        child: widget.child,
      );
}
