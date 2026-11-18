/// FCM-Wakeups sind ausschließlich für natives Android.
///
/// Der bedingte Export wählt den Stub für Web; auf Desktop wird zwar die
/// Android-Implementierung kompiliert, sie ist dort aber zur Laufzeit über
/// [FcmPushService.setup] deaktiviert (`Platform.isAndroid`) und wird nie
/// initialisiert. Web behält das bestehende Web-Push-System.
library;

export 'fcm_setup_result.dart';
export 'fcm_push_service_stub.dart'
    if (dart.library.io) 'fcm_push_service_android.dart';
