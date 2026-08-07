import 'package:flutter/material.dart';
import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';
import '../primitives/design_slider.dart';

/// An HSL color picker built from three labeled [DesignSlider]s.
///
/// Lets the user freely choose hue and saturation, while the lightness
/// slider is restricted to [minLightness]..[maxLightness] so the result can
/// never be near-white or near-black and stays readable in the UI. The picked
/// color is reported through [onChanged] on every interaction.
class DesignColorPicker extends StatefulWidget {
  const DesignColorPicker({
    required this.initialColor,
    required this.onChanged,
    super.key,
  });

  /// Lightness floor of selectable colors (readable range).
  static const double minLightness = 0.28;

  /// Lightness ceil of selectable colors (readable range).
  static const double maxLightness = 0.72;

  /// The color the picker starts from. Its lightness outside the readable
  /// range is clamped on first build.
  final Color initialColor;

  /// Called with the currently picked color.
  final ValueChanged<Color> onChanged;

  @override
  State<DesignColorPicker> createState() => _DesignColorPickerState();
}

class _DesignColorPickerState extends State<DesignColorPicker> {
  late HSLColor _hsl;

  @override
  void initState() {
    super.initState();
    _hsl = _clampLightness(HSLColor.fromColor(widget.initialColor));
  }

  HSLColor _clampLightness(HSLColor hsl) {
    final lightness = hsl.lightness.clamp(
      DesignColorPicker.minLightness,
      DesignColorPicker.maxLightness,
    );
    return hsl.withLightness(lightness);
  }

  Color _colorAt(double lightness) => _hsl
      .withLightness(lightness.clamp(0.0, 1.0))
      .toColor();

  void _update(HSLColor next) {
    setState(() => _hsl = next);
    widget.onChanged(next.toColor());
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final hueColor = HSLColor.fromAHSL(
      1,
      _hsl.hue,
      1,
      (DesignColorPicker.minLightness + DesignColorPicker.maxLightness) / 2,
    ).toColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _hsl.toColor(),
                shape: BoxShape.circle,
                border: Border.all(color: tokens.border, width: 1.5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DesignText(
                _hexString(_hsl.toColor()),
                style: DesignTextStyle.label,
                color: tokens.textLow,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DesignSlider(
          label: 'Farbton',
          value: _hsl.hue,
          min: 0,
          max: 360,
          valueText: '${_hsl.hue.round()}°',
          gradient: const LinearGradient(colors: _hueColors),
          onChanged: (h) => _update(_hsl.withHue(h)),
        ),
        const SizedBox(height: 12),
        DesignSlider(
          label: 'Sättigung',
          value: _hsl.saturation,
          min: 0,
          max: 1,
          valueText: '${(_hsl.saturation * 100).round()}%',
          gradient: LinearGradient(colors: [Colors.white, hueColor]),
          onChanged: (s) => _update(_hsl.withSaturation(s)),
        ),
        const SizedBox(height: 12),
        DesignSlider(
          label: 'Helligkeit',
          value: _hsl.lightness,
          min: DesignColorPicker.minLightness,
          max: DesignColorPicker.maxLightness,
          valueText: '${(_hsl.lightness * 100).round()}%',
          gradient: LinearGradient(
            colors: [
              _colorAt(DesignColorPicker.minLightness),
              _colorAt(DesignColorPicker.maxLightness),
            ],
          ),
          onChanged: (l) => _update(_hsl.withLightness(l)),
        ),
        const SizedBox(height: 8),
        DesignText(
          'Die Helligkeit ist so begrenzt, dass die Farbe immer gut lesbar bleibt.',
          style: DesignTextStyle.label,
          color: tokens.textLow,
        ),
      ],
    );
  }

  static String _hexString(Color c) =>
      '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
}

const List<Color> _hueColors = <Color>[
  Color(0xFFFF0000),
  Color(0xFFFFFF00),
  Color(0xFF00FF00),
  Color(0xFF00FFFF),
  Color(0xFF0000FF),
  Color(0xFFFF00FF),
  Color(0xFFFF0000),
];