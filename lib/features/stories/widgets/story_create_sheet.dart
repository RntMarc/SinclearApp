import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/image/image_compressor.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_text_field.dart';

/// Öffnet das Erstellungs-Sheet und liefert `true`, wenn eine Story angelegt
/// wurde (der Aufrufer aktualisiert dann den Feed).
Future<bool> showCreateStorySheet(BuildContext context) async {
  final created = await showDesignSheet<bool>(
    context: context,
    child: const _StoryCreateSheet(),
  );
  return created ?? false;
}

class _StoryCreateSheet extends StatefulWidget {
  const _StoryCreateSheet();

  @override
  State<_StoryCreateSheet> createState() => _StoryCreateSheetState();
}

class _StoryCreateSheetState extends State<_StoryCreateSheet> {
  final _captionController = TextEditingController();
  Uint8List? _imageBytes;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    final compressed = compressImage(
      bytes,
      maxDimension: 2000,
      maxBytes: 1024 * 1024,
    );
    if (compressed == null) {
      setState(() => _error = 'Bild konnte nicht verarbeitet werden.');
      return;
    }
    setState(() {
      _imageBytes = compressed;
      _error = null;
    });
  }

  Future<void> _publish() async {
    final image = _imageBytes;
    if (image == null) {
      setState(() => _error = 'Bitte wähle ein Bild.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final caption = _captionController.text.trim();
      await AppScope.of(context).stories.create(
        image: base64Encode(image),
        caption: caption.isEmpty ? null : caption,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Story konnte nicht veröffentlicht werden.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DesignText(
          'Story erstellen',
          style: DesignTextStyle.subtitle,
          color: tokens.textHigh,
        ),
        SizedBox(height: tokens.spaceLg),
        if (_imageBytes != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(tokens.radiusLg),
            child: Image.memory(
              _imageBytes!,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(height: tokens.spaceMd),
        ],
        if (_error != null) ...[
          DesignText(
            _error!,
            style: DesignTextStyle.body,
            color: tokens.danger,
          ),
          SizedBox(height: tokens.spaceMd),
        ],
        Row(
          children: [
            Expanded(
              child: DesignButton(
                variant: DesignButtonVariant.outlined,
                icon: Icons.camera_alt_rounded,
                label: 'Kamera',
                onPressed: _submitting ? null : () => _pick(ImageSource.camera),
              ),
            ),
            SizedBox(width: tokens.spaceMd),
            Expanded(
              child: DesignButton(
                variant: DesignButtonVariant.outlined,
                icon: Icons.photo_library_rounded,
                label: 'Galerie',
                onPressed: _submitting
                    ? null
                    : () => _pick(ImageSource.gallery),
              ),
            ),
          ],
        ),
        SizedBox(height: tokens.spaceLg),
        DesignTextField(
          controller: _captionController,
          hint: 'Bildunterschrift (optional)',
          prefixIcon: Icons.title_rounded,
          maxLines: 2,
          maxLength: 1000,
        ),
        SizedBox(height: tokens.spaceLg),
        DesignButton(
          variant: DesignButtonVariant.filled,
          label: 'Veröffentlichen',
          icon: Icons.send_rounded,
          fullWidth: true,
          loading: _submitting,
          onPressed: _submitting ? null : _publish,
        ),
      ],
    );
  }
}
