// ignore_for_file: prefer_initializing_formals, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io' show Platform;
import 'dart:ui' show DartPluginRegistrant;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../../../core/notifications/local_notification_helper.dart';
import '../../../firebase_options.dart';
import 'background_poller.dart';
import 'fcm_setup_result.dart';

/// Top-Level Background-Handler für Google FCM (nur Android).
///
/// STRIKTE DATENSCHUTZREGEL:
/// Die FCM-Nachricht selbst enthält keinerlei persönliche Inhalte (nur
/// `wakeup: "1"` und `notificationId`). Dieser Handler weckt die App im
/// Hintergrund auf und ruft den eigentlichen Inhalt direkt und authentifiziert
/// über [pollNotificationsHeadless] von der Sinclear-API ab.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kIsWeb) return;

  // Der Handler läuft in einem eigenen Isolate. Plugins (SharedPreferences)
  // und Firebase müssen dort erneut registriert/initialisiert werden.
  DartPluginRegistrant.ensureInitialized();
  try {
    await _initializeFirebase();
  } catch (e, st) {
    developer.log(
      'Firebase init in background isolate failed',
      error: e,
      stackTrace: st,
      name: 'fcm_push',
    );
  }

  final ok = await pollNotificationsHeadless(force: true);
  if (!ok) {
    final notificationId = message.data['notificationId'] as String?;
    if (notificationId != null && notificationId.isNotEmpty) {
      await LocalNotificationHelper.init();
      await LocalNotificationHelper.show(
        id: stableNotificationId(notificationId),
        title: 'Neue Mitteilung',
        body: 'Öffne Beyond, um deine neuen Benachrichtigungen zu lesen.',
        payload: jsonEncode({'id': notificationId, 'type': 'unknown'}),
      );
    }
  }
}

/// Initialisiert Firebase idempotent im aktuellen Isolate.
///
/// Auf Android existiert die native `[DEFAULT]`-App bereits, sobald eine
/// `google-services.json` eingebunden ist (FirebaseInitProvider). Beim Build
/// wird diese Datei aus derselben `.env` erzeugt wie die `--dart-define`-
/// Werte, deshalb sind beide Quellen identisch. Weichen sie dennoch ab
/// (z. B. alter lokaler Build), gewinnt die native Konfiguration: Sie ist die
/// einzige, die Firebase Installations für den Token-Abruf verwendet.
Future<void> _initializeFirebase() async {
  if (Firebase.apps.isNotEmpty) return;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app' || Firebase.apps.isEmpty) rethrow;
    developer.log(
      'Native Firebase app differs from build options; using '
      'google-services.json configuration',
      name: 'fcm_push',
    );
  }
}

/// Verwaltet die Google-FCM-Integration (ausschließlich natives Android).
///
/// Web/PWA verwendet niemals FCM, sondern immer Browser-Web-Push (`web/sw.js`).
class FcmPushService extends ChangeNotifier {
  static const _savedTokenKey = 'fcm_saved_token';

  final ApiClient _api;
  Future<String> Function()? _getToken;
  Future<void> Function()? _onWakeup;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundMessageSub;
  String? _fcmToken;
  bool _firebaseInitialized = false;
  bool _serverNotConfigured = false;

  FcmPushService({required ApiClient api}) : _api = api;

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  /// Initialisiert Firebase (nur Android), holt das FCM-Token, registriert es
  /// als `type: 'fcm'` bei der API und lauscht auf Wakeup-Pushes.
  Future<FcmSetupResult> setup({
    required Future<String> Function() getToken,
    required Future<void> Function() onWakeup,
  }) async {
    if (!_isAndroid) return FcmSetupResult.unavailable;
    _getToken = getToken;
    _onWakeup = onWakeup;

    final hadToken = await _hasSavedToken();
    _serverNotConfigured = false;

    try {
      await _ensureFirebaseInitialized();
    } catch (e, st) {
      developer.log(
        'FCM firebase_init failed',
        error: e,
        stackTrace: st,
        name: 'fcm_push',
      );
      return _isUnavailable(e)
          ? FcmSetupResult.unavailable
          : FcmSetupResult.failed;
    }

    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        developer.log(
          'FCM permission not granted: ${settings.authorizationStatus}',
          name: 'fcm_push',
        );
        return FcmSetupResult.permissionDenied;
      }

      // Das Manifest deaktiviert die native Auto-Init beim Prozessstart.
      // Erst die ausdrückliche Zustimmung oben darf einen Token erzeugen.
      // Listener erst danach: vorher gibt es nichts zu registrieren.
      await _setAutoInitEnabled(true);
      _listenForMessages();

      final String? fcmToken;
      try {
        fcmToken = await messaging.getToken();
      } catch (e, st) {
        developer.log(
          'FCM fcm_get_token failed',
          error: e,
          stackTrace: st,
          name: 'fcm_push',
        );
        if (hadToken) return FcmSetupResult.ready;
        return _isUnavailable(e)
            ? FcmSetupResult.unavailable
            : FcmSetupResult.failed;
      }
      if (fcmToken == null || fcmToken.isEmpty) {
        developer.log('FCM token is empty', name: 'fcm_push');
        return hadToken ? FcmSetupResult.ready : FcmSetupResult.failed;
      }
      _fcmToken = fcmToken;
      if (!await _registerToken(fcmToken) &&
          (_serverNotConfigured || !hadToken)) {
        // Ein transientes Registrierungsproblem darf eine bereits bestehende
        // Zustellung nicht zerstören; nur einen nie registrierten Token
        // verwerfen, damit Google nichts Verwaistes behält. Eine explizite
        // Server-Ablehnung (FCM nicht konfiguriert) ist kein transienter Fall.
        await _discardToken();
        return FcmSetupResult.failed;
      }
      return FcmSetupResult.ready;
    } catch (e, st) {
      developer.log(
        'FCM setup failed',
        error: e,
        stackTrace: st,
        name: 'fcm_push',
      );
      // Kurzzeitig offline beim Kaltstart: Ein bereits serverseitig
      // registrierter Token bleibt gültig, kein Setup-Fehler in der UI.
      if (hadToken && _firebaseInitialized) return FcmSetupResult.ready;
      return _isUnavailable(e)
          ? FcmSetupResult.unavailable
          : FcmSetupResult.failed;
    }
  }

  /// Meldet das Gerät von FCM-Wakeup-Pushes ab (Methodenwechsel oder Logout).
  Future<void> unregister({String? token}) async {
    if (!_isAndroid) return;

    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    await _foregroundMessageSub?.cancel();
    _foregroundMessageSub = null;

    var endpoint = _fcmToken;
    try {
      final prefs = await SharedPreferences.getInstance();
      endpoint ??= prefs.getString(_savedTokenKey);
      await prefs.remove(_savedTokenKey);
    } catch (_) {}

    if (endpoint != null && endpoint.isNotEmpty) {
      try {
        final accessToken = token ?? await _getToken?.call();
        if (accessToken != null && accessToken.isNotEmpty) {
          await _api.delete(
            '/notifications/push-subscription',
            body: {'endpoint': endpoint},
            token: accessToken,
          );
        }
      } catch (e) {
        developer.log('Failed to unregister FCM token: $e', name: 'fcm_push');
      }
    }

    // Auto-Init vor dem Löschen abschalten, damit Firebase nicht sofort einen
    // neuen Token erzeugt und Google kontaktiert.
    await _setAutoInitEnabled(false);
    try {
      if (_firebaseInitialized) {
        await FirebaseMessaging.instance.deleteToken();
      }
    } catch (_) {}
    _fcmToken = null;
  }

  Future<void> _ensureFirebaseInitialized() async {
    if (_firebaseInitialized) return;
    await _initializeFirebase();
    _firebaseInitialized = true;
  }

  void _listenForMessages() {
    _tokenRefreshSub ??= FirebaseMessaging.instance.onTokenRefresh.listen((
      newToken,
    ) {
      _fcmToken = newToken;
      unawaited(_registerToken(newToken));
    });

    _foregroundMessageSub ??= FirebaseMessaging.onMessage.listen((_) {
      final callback = _onWakeup;
      if (callback != null) {
        unawaited(callback());
      }
    });
  }

  /// Registriert [endpoint] bei der API und meldet nur bei Erfolg `true`.
  ///
  /// Der Token wird erst nach erfolgreicher Registrierung lokal gespeichert,
  /// damit ein abgelehnter Request nicht als eingerichtete Zustellung gilt.
  Future<bool> _registerToken(String endpoint) async {
    final getToken = _getToken;
    if (getToken == null) return false;

    try {
      final accessToken = await getToken();
      await _api.post(
        '/notifications/push-subscription',
        body: {'type': 'fcm', 'endpoint': endpoint},
        token: accessToken,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 503 && e.errorCode == 'fcm_not_configured') {
        _serverNotConfigured = true;
      }
      developer.log(
        'FCM api_register_token failed: status=${e.statusCode} '
        'code=${e.errorCode}',
        name: 'fcm_push',
      );
      return false;
    } catch (e) {
      developer.log('FCM api_register_token failed: $e', name: 'fcm_push');
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_savedTokenKey, endpoint);
    } catch (_) {}
    return true;
  }

  Future<bool> _hasSavedToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getString(_savedTokenKey) ?? '').isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Verwirft einen lokal erzeugten Token, der serverseitig nicht registriert
  /// werden konnte, damit Google keinen verwaisten Token behält.
  Future<void> _discardToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_savedTokenKey);
    } catch (_) {}
    await _setAutoInitEnabled(false);
    try {
      if (_firebaseInitialized) {
        await FirebaseMessaging.instance.deleteToken();
      }
    } catch (_) {}
    _fcmToken = null;
  }

  Future<void> _setAutoInitEnabled(bool enabled) async {
    if (!_firebaseInitialized) return;
    try {
      await FirebaseMessaging.instance.setAutoInitEnabled(enabled);
    } catch (e) {
      developer.log('Failed to set FCM auto-init: $e', name: 'fcm_push');
    }
  }

  /// Erkennt fehlende Google Play-Dienste, damit die UI `unavailable`
  /// statt eines generischen Registrierungsfehlers anzeigen kann.
  bool _isUnavailable(Object error) {
    final code = switch (error) {
      FirebaseException(:final code) => code,
      PlatformException(:final code) => code,
      _ => '',
    };
    return code == 'MISSING_INSTANCEID_SERVICE' ||
        code == 'missing-instanceid-service' ||
        code == 'SERVICE_NOT_AVAILABLE';
  }
}
