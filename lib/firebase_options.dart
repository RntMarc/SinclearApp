// Firebase client configuration is injected at build time (see deploy.py),
// never committed. deploy.py also regenerates the gitignored
// android/app/google-services.json from the same .env values, so the native
// SDK and these options always match. Local Android builds without
// --dart-define fall back to the native resources from google-services.json.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with the native Android app.
///
/// Web/PWA uses standard browser Web Push (VAPID via `web/sw.js`) and never
/// initializes Firebase.
class DefaultFirebaseOptions {
  static FirebaseOptions? get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Firebase is not used on Web — the PWA uses browser Web Push.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are only configured for Android.',
        );
    }
  }

  /// Returns `null` when no build-time configuration was supplied.
  ///
  /// In that case [Firebase.initializeApp] uses the native resources generated
  /// from the gitignored `android/app/google-services.json`.
  static FirebaseOptions? get android {
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const appId = String.fromEnvironment('FIREBASE_APP_ID');
    const messagingSenderId = String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
    );
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');

    if (apiKey.isEmpty ||
        appId.isEmpty ||
        messagingSenderId.isEmpty ||
        projectId.isEmpty) {
      return null;
    }

    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
    );
  }
}
