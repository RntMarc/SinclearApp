import 'package:flutter/material.dart';
import '../../theme/design_theme.dart';

/// Pulsierender farbiger Punkt zur Kennzeichnung ungelesener Aktivität.
///
/// Sanfter Skalen-/Opacity-Puls in [DesignTokens.accentA] (überschreibbar).
/// Respektiert `MediaQuery.disableAnimations` und zeigt dann einen statischen
/// Punkt. Der Punkt ist klein genug, um neben Menü-Einträgen oder Icons zu
/// sitzen, ohne Layout zu verbrauchen.
class DesignPulseDot extends StatefulWidget {
  const DesignPulseDot({this.size = 8, this.color, super.key});

  final double size;

  /// Punktfarbe; Standard ist [DesignTokens.accentA].
  final Color? color;

  @override
  State<DesignPulseDot> createState() => _DesignPulseDotState();
}

class _DesignPulseDotState extends State<DesignPulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(
    begin: 0.4,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  late final Animation<double> _scale = Tween<double>(
    begin: 0.8,
    end: 1.2,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final color = widget.color ?? tokens.accentA;
    if (MediaQuery.of(context).disableAnimations) {
      return _dot(color, 1.0, 1.0);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => _dot(color, _opacity.value, _scale.value),
    );
  }

  Widget _dot(Color color, double opacity, double scale) {
    return Semantics(
      label: 'Ungelesene Aktivität',
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: opacity),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5 * opacity),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
