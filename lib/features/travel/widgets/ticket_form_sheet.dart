import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../services/travel_service.dart';
import 'qr_scanner_page.dart';

Future<bool?> showTicketFormSheet({
  required BuildContext context,
  required TravelService service,
  String? tripId,
  String? eventId,
}) {
  final tokens = DesignTheme.of(context);
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _TicketFormSheet(
      service: service,
      tokens: tokens,
      tripId: tripId,
      eventId: eventId,
    ),
  );
}

class _TicketFormSheet extends StatefulWidget {
  final TravelService service;
  final DesignTokens tokens;
  final String? tripId;
  final String? eventId;

  const _TicketFormSheet({
    required this.service,
    required this.tokens,
    this.tripId,
    this.eventId,
  });

  @override
  State<_TicketFormSheet> createState() => _TicketFormSheetState();
}

class _TicketFormSheetState extends State<_TicketFormSheet> {
  final _qrController = TextEditingController();
  Uint8List? _imageBytes;
  bool _saving = false;

  @override
  void dispose() {
    _qrController.dispose();
    super.dispose();
  }

  Future<void> _scanQr() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerPage()),
    );
    if (result != null) {
      _qrController.text = result;
    }
  }

  Future<void> _pickImage() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bild auswählen'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, ImageSource.camera),
            child: const Text('Kamera'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
            child: const Text('Galerie'),
          ),
        ],
      ),
    );
    if (source == null) return;

    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(source: source, maxWidth: 1024);
      if (photo == null) return;
      final bytes = await photo.readAsBytes();
      if (!mounted) return;
      setState(() => _imageBytes = bytes);
    } catch (_) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Hinweis'),
          content: const Text('Kamera nicht verfügbar'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  bool get _hasContent =>
      _qrController.text.isNotEmpty || _imageBytes != null;

  Future<void> _save() async {
    if (!_hasContent) return;
    setState(() => _saving = true);
    try {
      await widget.service.createUserTicket(
        qrcode: _qrController.text.isNotEmpty ? _qrController.text : null,
        image: _imageBytes != null ? base64Encode(_imageBytes!) : null,
        tripId: widget.tripId,
        eventId: widget.eventId,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Fehler'),
          content: Text('Fehler beim Speichern: $e'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tokens;
    return Padding(
      padding: EdgeInsets.all(t.spaceLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DesignText(
                'Ticket hinzufügen',
                style: DesignTextStyle.subtitle,
                color: t.textHigh,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: t.spaceMd),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qrController,
                  decoration: const InputDecoration(
                    labelText: 'QR-Code',
                    hintText: 'Scannen oder manuell eingeben',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ),
              SizedBox(width: t.spaceSm),
              DesignIconButton(
                icon: Icons.qr_code_scanner_rounded,
                tinted: true,
                onPressed: _scanQr,
              ),
            ],
          ),
          SizedBox(height: t.spaceMd),
          DesignButton(
            variant: DesignButtonVariant.outlined,
            label: _imageBytes != null ? 'Bild ändern' : 'Bild auswählen',
            icon: Icons.image_rounded,
            onPressed: _pickImage,
          ),
          if (_imageBytes != null) ...[
            SizedBox(height: t.spaceSm),
            ClipRRect(
              borderRadius: BorderRadius.circular(t.radiusSm),
              child: Image.memory(
                _imageBytes!,
                height: 100,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
          ],
          SizedBox(height: t.spaceXl),
          Center(
            child: DesignButton(
              variant: DesignButtonVariant.filled,
              label: 'Speichern',
              icon: _saving ? Icons.hourglass_top_rounded : Icons.check_rounded,
              onPressed: _saving ? null : _save,
            ),
          ),
        ],
      ),
    );
  }
}
