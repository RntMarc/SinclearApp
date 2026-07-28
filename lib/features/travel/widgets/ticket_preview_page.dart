import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screen_brightness/screen_brightness.dart';

import '../../../core/image/image_provider_helper.dart';

class TicketPreviewPage extends StatefulWidget {
  final String? qrcode;
  final String? image;
  final String title;

  const TicketPreviewPage({
    super.key,
    this.qrcode,
    this.image,
    required this.title,
  });

  @override
  State<TicketPreviewPage> createState() => _TicketPreviewPageState();
}

class _TicketPreviewPageState extends State<TicketPreviewPage> {
  @override
  void initState() {
    super.initState();
    ScreenBrightness().setScreenBrightness(1.0);
  }

  @override
  void dispose() {
    ScreenBrightness().resetScreenBrightness();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      backgroundColor: Colors.black,
      body: Center(
        child: widget.image != null && resolveImageProvider(widget.image) != null
            ? InteractiveViewer(
                maxScale: 5,
                child: Image(
                  image: resolveImageProvider(widget.image!)!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              )
            : widget.qrcode != null
                ? QrImageView(
                    data: widget.qrcode!,
                    size: MediaQuery.of(context).size.width * 0.85,
                    backgroundColor: Colors.white,
                  )
                : const Text('Keine Vorschau', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
