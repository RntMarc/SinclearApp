import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/url_helper.dart';
import '../../theme/design_theme.dart';

/// Text style tiers available across the catalog.
enum DesignTextStyle { display, title, subtitle, body, label }

/// Typography wrapper that resolves its style from the active [DesignTokens].
///
/// All catalog text goes through this so font family, weight and color stay
/// consistent with the selected design.
///
/// Complete `http://` / `https://` URLs in [text] are rendered as tappable,
/// underlined links that open in the external browser ([linkColor] controls
/// their color, default `tokens.primary`). Bare hosts and `mailto:` addresses
/// stay plain text.
///
/// Links only appear in prose ([DesignTextStyle.body]); titles, labels and
/// buttons stay plain. Body-styled names or values inside controls opt out
/// with `linkify: false`.
class DesignText extends StatelessWidget {
  const DesignText(
    this.text, {
    this.style = DesignTextStyle.body,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.letterSpacing,
    this.linkColor,
    this.linkify,
    super.key,
  });

  final String text;
  final DesignTextStyle style;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? letterSpacing;

  /// Color of detected links. Defaults to `tokens.primary`; pass the surface
  /// foreground (e.g. `tokens.textOnPrimary`) on filled backgrounds.
  final Color? linkColor;

  /// Whether URLs become tappable links.
  ///
  /// `null` (the default) enables links only for [DesignTextStyle.body], i.e.
  /// prose such as descriptions and messages. Pass `false` for body-styled
  /// titles, names or values rendered inside a control.
  final bool? linkify;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final baseColor = color ?? tokens.textHigh;
    final textStyle = switch (style) {
      DesignTextStyle.display => tokens.displayStyle(baseColor),
      DesignTextStyle.title => tokens.titleStyle(baseColor),
      DesignTextStyle.subtitle => tokens.subtitleStyle(baseColor),
      DesignTextStyle.label => tokens.labelStyle(baseColor),
      DesignTextStyle.body => tokens.bodyStyle(baseColor),
    }.copyWith(letterSpacing: letterSpacing);
    final linkify = this.linkify ?? style == DesignTextStyle.body;
    final segments = linkify ? splitUrlSegments(text) : const <UrlSegment>[];
    final hasLink = segments.any((segment) => segment.url != null);
    if (!hasLink) {
      return Text(
        text,
        style: textStyle,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow ?? TextOverflow.clip,
      );
    }
    return _LinkedText(
      segments: segments,
      style: textStyle,
      linkColor: linkColor ?? tokens.primary,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }
}

/// Renders pre-split [segments] as rich text and owns one tap recognizer per
/// link, so they are disposed with the widget instead of leaking per build.
class _LinkedText extends StatefulWidget {
  const _LinkedText({
    required this.segments,
    required this.style,
    required this.linkColor,
    required this.overflow,
    this.textAlign,
    this.maxLines,
  });

  final List<UrlSegment> segments;
  final TextStyle style;
  final Color linkColor;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow overflow;

  @override
  State<_LinkedText> createState() => _LinkedTextState();
}

class _LinkedTextState extends State<_LinkedText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  List<InlineSpan> _buildSpans() {
    final linkCount = widget.segments.where((s) => s.url != null).length;
    if (linkCount != _recognizers.length) {
      _disposeRecognizers();
      _recognizers.addAll(
        List.generate(linkCount, (_) => TapGestureRecognizer()),
      );
    }
    final linkStyle = TextStyle(
      color: widget.linkColor,
      decoration: TextDecoration.underline,
      decorationColor: widget.linkColor,
      fontWeight: FontWeight.w600,
    );
    final spans = <InlineSpan>[];
    var linkIndex = 0;
    for (final segment in widget.segments) {
      final url = segment.url;
      if (url == null) {
        spans.add(TextSpan(text: segment.text));
        continue;
      }
      final recognizer = _recognizers[linkIndex++];
      recognizer.onTap = () => launchExternalUrl(url);
      spans.add(
        TextSpan(text: segment.text, style: linkStyle, recognizer: recognizer),
      );
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: _buildSpans()),
      style: widget.style,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}
