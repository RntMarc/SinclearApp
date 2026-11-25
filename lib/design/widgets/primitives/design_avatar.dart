import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/image/image_provider_helper.dart';
import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';

/// Circular avatar showing an image or initials. Builds on the token palette
/// for the fallback background and supports HTTP(S), `data:` and raw base64
/// image sources via [resolveImageProvider].
///
/// Bei Vorschaubildern (`data:...;preview=1;hash=...;base64,...`) zeigt der
/// Avatar automatisch das kleine Vorschaubild. Große Avatare (`size >= 64`,
/// z. B. Profil) bieten zusätzlich einen „HD laden“-Button, der die volle
/// Qualität nachlädt; kleine Avatare (Kommentare, Chat-Listen) verzichten
/// darauf, da dort kein Qualitätsunterschied sichtbar ist.
class DesignAvatar extends StatelessWidget {
  const DesignAvatar({
    this.imageUrl,
    this.name = '',
    this.size = 48,
    super.key,
  });

  final String? imageUrl;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : '';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: tokens.border.withValues(alpha: 0.6)),
        boxShadow: tokens.surfaceShadow,
      ),
      child: ClipOval(
        child: _AvatarImage(imageUrl: imageUrl, initials: initials, size: size),
      ),
    );
  }
}

class _AvatarImage extends StatefulWidget {
  const _AvatarImage({
    required this.imageUrl,
    required this.initials,
    required this.size,
  });

  final String? imageUrl;
  final String initials;
  final double size;

  @override
  State<_AvatarImage> createState() => _AvatarImageState();
}

class _AvatarImageState extends State<_AvatarImage> {
  Uint8List? _fullBytes;
  bool _loading = false;

  @override
  void didUpdateWidget(covariant _AvatarImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _fullBytes = null;
    }
  }

  Future<void> _loadFull() async {
    final hash = parseImageSource(widget.imageUrl).fullQualityHash;
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
    final parsed = parseImageSource(widget.imageUrl);
    final provider = _fullBytes != null
        ? MemoryImage(_fullBytes!)
        : resolveImageProvider(widget.imageUrl);

    final Widget child;
    if (provider == null) {
      child = _initials(tokens);
    } else {
      child = Image(
        image: provider,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _initials(tokens),
      );
    }

    final showHd = parsed.isPreview && widget.size >= 64 && _fullBytes == null;
    if (!showHd) return child;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        child,
        Padding(
          padding: const EdgeInsets.all(4),
          child: GestureDetector(
            onTap: _loading ? null : _loadFull,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.hd_rounded, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _initials(DesignTokens tokens) {
    return Container(
      width: widget.size,
      height: widget.size,
      color: tokens.surfaceVariant,
      alignment: Alignment.center,
      child: DesignText(
        widget.initials,
        style: DesignTextStyle.label,
        color: tokens.primary,
      ),
    );
  }
}
