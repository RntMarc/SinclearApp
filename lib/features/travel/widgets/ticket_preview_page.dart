import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/image/image_provider_helper.dart';

class TicketPreviewPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      backgroundColor: Colors.black,
      body: Center(
        child: image != null && resolveImageProvider(image) != null
            ? InteractiveViewer(
                maxScale: 5,
                child: Image(
                  image: resolveImageProvider(image!)!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              )
            : qrcode != null
                ? QrImageView(data: qrcode!, size: MediaQuery.of(context).size.width * 0.85)
                : const Text('Keine Vorschau', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
