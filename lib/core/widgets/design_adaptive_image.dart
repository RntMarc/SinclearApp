import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../design/theme/design_theme.dart';
import '../di/app_scope.dart';
import '../image/image_provider_helper.dart';

/// Ein Inhaltsbild, das bei schlechter Verbindung zunächst das von der API
/// mitgelieferte Vorschaubild zeigt und auf Wunsch die volle Qualität nachlädt.
///
/// Erkennt Vorschau-Quellen (`data:...;preview=1;hash=...;base64,...`) über
/// [parseImageSource]. Ist [enableHd] aktiv, blendet es einen „HD laden“-Button
/// ein, der die volle Qualität über `AppScope.media` nachlädt (lokal gecacht)
/// und weich auf das Original umschaltet.
class DesignAdaptiveImage extends StatefulWidget {
  final String? source;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final bool enableHd;

  const DesignAdaptiveImage({
    super.key,
    this.source,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.enableHd = true,
  });

  @override
  State<DesignAdaptiveImage> createState() => _DesignAdaptiveImageState();
}

class _DesignAdaptiveImageState extends State<DesignAdaptiveImage> {
  Uint8List? _fullBytes;
  bool _loading = false;

  @override
  void didUpdateWidget(covariant DesignAdaptiveImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      _fullBytes = null;
    }
  }

  Future<void> _loadFull() async {
    final hash = parseImageSource(widget.source).fullQualityHash;
    if (hash == null || _loading) return;
    setState(() => _loading = true);
    try {
      final bytes = await AppScope.of(context).media.loadFullQuality(hash);
      if (!mounted) return;
      setState(() => _fullBytes = bytes);
    } catch (_) {
      // Still ignorieren; das Vorschaubild bleibt sichtbar.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final parsed = parseImageSource(widget.source);
    final provider = _fullBytes != null
        ? MemoryImage(_fullBytes!)
        : resolveImageProvider(widget.source);
    final showHd = widget.enableHd && parsed.isPreview && _fullBytes == null;

    final Widget content;
    if (provider == null) {
      content = widget.placeholder ?? const SizedBox.shrink();
    } else {
      content = Image(
        image: provider,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (_, _, _) =>
            widget.placeholder ?? const SizedBox.shrink(),
      );
    }

    final image = ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: content,
    );

    if (!showHd) return image;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        image,
        Padding(
          padding: const EdgeInsets.all(8),
          child: _HdButton(loading: _loading, onTap: _loadFull, tokens: tokens),
        ),
      ],
    );
  }
}

class _HdButton extends StatelessWidget {
  const _HdButton({
    required this.loading,
    required this.onTap,
    required this.tokens,
  });

  final bool loading;
  final VoidCallback onTap;
  final DesignTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Volle Qualität laden',
      child: GestureDetector(
        onTap: loading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
          ),
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.hd_rounded, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}
