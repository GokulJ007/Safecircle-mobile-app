import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// A robust, reusable location service to manage GPS access and permissions.
class LocationService {
  LocationService._();

  static final LocationService instance = LocationService._();

  /// Checks if the device's location services are enabled.
  Future<bool> isServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Checks the current permission status and requests permission if needed.
  /// Returns the final [LocationPermission] state.
  Future<LocationPermission> handlePermission() async {
    bool serviceEnabled = await isServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled.
      return LocationPermission.denied;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied.
        return LocationPermission.denied;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever.
      return LocationPermission.deniedForever;
    }

    return permission;
  }

  /// Gets the current location of the device.
  /// Throws standard Geolocator exceptions or custom error messages.
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await isServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw PermissionDeniedException('Location permissions are not granted.');
    }

    // Fetch the current position with high accuracy
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  /// Obtains a stream of the device's location.
  /// Location updates are triggered when the device moves by [distanceFilter] meters.
  Stream<Position> getPositionStream({int distanceFilter = 5}) {
    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilter,
    );
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// Opens the app settings screen to let the user manually enable permissions.
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Opens the device settings screen to let the user manually enable location services.
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }
}
