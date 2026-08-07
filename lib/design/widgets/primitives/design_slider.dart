import 'package:flutter/material.dart';
import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';

/// A design-token based slider with a labeled gradient track.
///
/// Renders the [label] together with a live [valueText] readout above a
/// rounded gradient track. Dragging the track (or tapping it) calls
/// [onChanged] with a value clamped to [min]..[max]. [gradient] paints the
/// whole track, so callers can constrain the shown colors to the selectable
/// range (e.g. hiding the near-white/near-black parts of a lightness ramp).
class DesignSlider extends StatelessWidget {
  const DesignSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.valueText,
    this.gradient,
    super.key,
  });

  /// German caption shown above the track (e.g. "Helligkeit").
  final String label;

  /// Current value within [min]..[max].
  final double value;

  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  /// Formatted current value behind the label (e.g. "46%").
  final String valueText;

  /// Paints the track. Defaults to a primary-tinted ramp.
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    const height = 18.0;
    const thumbInset = 8.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: DesignText(label, style: DesignTextStyle.label),
            ),
            DesignText(
              valueText,
              style: DesignTextStyle.label,
              color: tokens.textLow,
            ),
          ],
        ),
        SizedBox(height: tokens.spaceXs),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final span = width - 2 * thumbInset;
            final t = ((value - min) / (max - min)).clamp(0.0, 1.0);
            final x = thumbInset + t * span;

            void pick(double dx) {
              final fraction = ((dx - thumbInset) / span).clamp(0.0, 1.0);
              onChanged(min + fraction * (max - min));
            }

            return GestureDetector(
              onPanDown: (d) => pick(d.localPosition.dx),
              onPanUpdate: (d) => pick(d.localPosition.dx),
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(height / 2),
                  gradient: gradient ??
                      LinearGradient(
                        colors: [tokens.surfaceVariant, tokens.primary],
                      ),
                  border: Border.all(color: tokens.border.withValues(alpha: 0.6)),
                  boxShadow: tokens.surfaceShadow,
                ),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: <Widget>[
                    Positioned(left: x - 7, child: const _SliderThumb()),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SliderThumb extends StatelessWidget {
  const _SliderThumb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
    );
  }
}