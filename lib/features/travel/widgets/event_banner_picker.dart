import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

/// Ob das Banner-Bild (3.5:1, ≤500KB/2000px) auf dieser Plattform gewählt
/// werden kann — eine Crop-UI existiert nur auf Android/iOS/Web.
bool get eventBannerSupported =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

/// Wählt ein Bild, schneidet es auf 3.5:1 zu und liefert es Base64-kodiert
/// zurück. `null` bei Abbruch oder fehlender Plattform-Unterstützung.
Future<String?> pickEventBanner(BuildContext context) async {
  final picked = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 3000,
  );
  if (picked == null) return null;
  if (!context.mounted) return null;

  final cropped = await ImageCropper().cropImage(
    sourcePath: picked.path,
    maxWidth: 2000,
    aspectRatio: const CropAspectRatio(ratioX: 7, ratioY: 2),
    compressFormat: ImageCompressFormat.jpg,
    compressQuality: 85,
    uiSettings: [
      if (kIsWeb) WebUiSettings(context: context),
      if (defaultTargetPlatform == TargetPlatform.android)
        AndroidUiSettings(toolbarTitle: 'Banner zuschneiden', lockAspectRatio: true),
      if (defaultTargetPlatform == TargetPlatform.iOS)
        IOSUiSettings(title: 'Banner zuschneiden', aspectRatioLockEnabled: true),
    ],
  );
  if (cropped == null) return null;

  final bytes = await cropped.readAsBytes();
  return base64Encode(bytes);
}
