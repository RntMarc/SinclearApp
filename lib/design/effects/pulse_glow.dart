import 'package:flutter/material.dart';
import '../theme/design_theme.dart';

/// Umrandet sein Kind mit einem sanft pulsierenden farbigen Glow an der Kante
/// („dort wo der Schatten ist"). Das Kind deckt die Mitte ab, sodass nur der
/// Rand leuchtet — subtil, aber wahrnehmbar.
///
/// Respektiert `MediaQuery.disableAnimations` und zeigt dann einen statischen,
/// gedämpften Glow. Blur-Radien leiten sich aus [DesignTokens.glowBlur] ab.
class DesignPulseGlow extends StatefulWidget {
  const DesignPulseGlow({
    required this.child,
    required this.color,
    required this.radius,
    super.key,
  });

  final Widget child;
  final Color color;
  final double radius;

  @override
  State<DesignPulseGlow> createState() => _DesignPulseGlowState();
}

class _DesignPulseGlowState extends State<DesignPulseGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  late final Animation<double> _alpha = Tween<double>(
    begin: 0.10,
    end: 0.35,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    if (MediaQuery.of(context).disableAnimations) {
      return _glow(tokens, 0.22);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => _glow(tokens, _alpha.value),
    );
  }

  Widget _glow(DesignTokens tokens, double alpha) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        boxShadow: [
          BoxShadow(
            color: widget.color.withValues(alpha: alpha),
            blurRadius: tokens.glowBlur * 0.7,
          ),
          BoxShadow(
            color: widget.color.withValues(alpha: alpha * 0.6),
            blurRadius: tokens.glowBlur * 1.4,
          ),
        ],
      ),
      child: widget.child,
    );
  }
}
