import 'package:flutter/material.dart';
import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';
import '../primitives/design_text_field.dart';

/// A compact HSV color picker in the catalog style.
///
/// Lets the user freely choose any color via a saturation/value pane, a hue
/// slider and a hexadecimal input. The picked color is reported through
/// [onChanged] on every interaction, so callers can preview live.
class DesignColorPicker extends StatefulWidget {
  const DesignColorPicker({
    required this.initialColor,
    required this.onChanged,
    super.key,
  });

  /// The color the picker starts from.
  final Color initialColor;

  /// Called with the currently picked color.
  final ValueChanged<Color> onChanged;

  @override
  State<DesignColorPicker> createState() => _DesignColorPickerState();
}

class _DesignColorPickerState extends State<DesignColorPicker> {
  late HSVColor _hsv;
  late final TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initialColor);
    _hexController = TextEditingController(
      text: _hexString(widget.initialColor),
    );
    _hexController.addListener(_onHexChanged);
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  static String _hexString(Color c) =>
      '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  void _emit(Color color) {
    widget.onChanged(color);
  }

  void _updateHsv(HSVColor hsv) {
    setState(() => _hsv = hsv);
    final color = hsv.toColor();
    _hexController.text = _hexString(color);
    _emit(color);
  }

  /// Applies a user-entered HEX value. Ignored while the text was written
  /// programmatically (feedback from [_updateHsv]).
  void _onHexChanged() {
    final text = _hexController.text;
    if (text == _hexString(_hsv.toColor())) return;
    final cleaned = text.replaceAll('#', '');
    if (cleaned.length != 6) return;
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return;
    _updateHsv(HSVColor.fromColor(Color(0xFF000000 | value)));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final hue = _hsv.hue;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SatValuePane(
          hsv: _hsv,
          onChanged: _updateHsv,
        ),
        const SizedBox(height: 16),
        _HueSlider(
          hue: hue,
          onChanged: (h) => _updateHsv(_hsv.withHue(h)),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _hsv.toColor(),
                shape: BoxShape.circle,
                border: Border.all(color: tokens.border, width: 1.5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DesignTextField(
                controller: _hexController,
                hint: '#RRGGBB',
                keyboardType: TextInputType.text,
                prefixIcon: Icons.tag_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DesignText(
          'Live-Vorschau oder HEX-Wert eingeben.',
          style: DesignTextStyle.label,
          color: tokens.textLow,
        ),
      ],
    );
  }
}

class _SatValuePane extends StatelessWidget {
  const _SatValuePane({required this.hsv, required this.onChanged});

  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  @override
  Widget build(BuildContext context) {
    final hueColor = HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const height = 160.0;
        final sat = (hsv.saturation * width).clamp(0.0, width);
        final val = ((1 - hsv.value) * height).clamp(0.0, height);

        return GestureDetector(
          onPanDown: (d) => _pick(d.localPosition, width, height),
          onPanUpdate: (d) => _pick(d.localPosition, width, height),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [Colors.white, hueColor],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Colors.transparent, Colors.black],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: sat - 7,
                  top: val - 7,
                  child: _Thumb(color: hsv.toColor()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _pick(Offset offset, double width, double height) {
    final saturation = (offset.dx / width).clamp(0.0, 1.0);
    final value = (1 - offset.dy / height).clamp(0.0, 1.0);
    onChanged(hsv.withSaturation(saturation).withValue(value));
  }
}

class _HueSlider extends StatelessWidget {
  const _HueSlider({required this.hue, required this.onChanged});

  final double hue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const height = 20.0;
        final x = (hue / 360 * width).clamp(0.0, width);

        return GestureDetector(
          onPanDown: (d) => _pick(d.localPosition.dx, width),
          onPanUpdate: (d) => _pick(d.localPosition.dx, width),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: _hueColors,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: <Widget>[
                Positioned(
                  left: x - 7,
                  child: const _Thumb(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _pick(double dx, double width) {
    final h = (dx / width * 360).clamp(0.0, 359.0);
    onChanged(h);
  }
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

class _Thumb extends StatelessWidget {
  const _Thumb({this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
    );
  }
}