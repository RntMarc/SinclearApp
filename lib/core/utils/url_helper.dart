import 'package:url_launcher/url_launcher.dart';

/// Launches a URL in the device's external browser application.
Future<void> launchExternalUrl(String rawUrl) async {
  var url = rawUrl.trim();
  if (url.isEmpty) return;
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    url = 'https://$url';
  }
  final uri = Uri.tryParse(url);
  if (uri != null) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
