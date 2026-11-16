/// FCM-Wakeups sind ausschließlich für natives Android.
///
/// Auf Web und Desktop wird der Stub eingebunden, damit die Firebase-Pakete
/// nicht in diese Builds gelangen. Web behält das bestehende Web-Push-System.
library;

export 'fcm_push_service_stub.dart'
    if (dart.library.io) 'fcm_push_service_android.dart';
