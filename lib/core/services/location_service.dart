import 'package:geolocator/geolocator.dart';

/// Thrown when GPS / location services are turned off on the device.
class LocationServicesOffException implements Exception {
  const LocationServicesOffException();
}

/// Thrown when the user denies the location permission request.
class LocationPermissionDeniedException implements Exception {
  const LocationPermissionDeniedException();
}

/// Thrown when permission is permanently denied and the user must enable it
/// in the system settings.
class LocationPermissionDeniedForeverException implements Exception {
  const LocationPermissionDeniedForeverException();
}

/// Thin wrapper around [Geolocator] that ensures service + permission checks
/// are performed before requesting the current position.
class LocationService {
  LocationService._();

  /// Resolves the current device position.
  ///
  /// Throws [LocationServicesOffException] when GPS / location services are
  /// turned off, [LocationPermissionDeniedException] when the user denies the
  /// request, and [LocationPermissionDeniedForeverException] when permission
  /// was denied permanently. On Android/iOS the permission prompt is shown
  /// automatically on the first call.
  static Future<Position> determinePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServicesOffException();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationPermissionDeniedException();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionDeniedForeverException();
    }

    return Geolocator.getCurrentPosition();
  }
}
