import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:latlong2/latlong.dart';

class ARNavigationService {
  static const double _earthRadius = 6371000; // Earth's radius in meters

  /// Calculate distance between two GPS coordinates
  static double calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371000; // Earth's radius in meters

    double lat1Rad = _degreesToRadians(start.latitude);
    double lat2Rad = _degreesToRadians(end.latitude);
    double deltaLatRad = _degreesToRadians(end.latitude - start.latitude);
    double deltaLonRad = _degreesToRadians(end.longitude - start.longitude);

    double a =
        sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLonRad / 2) *
            sin(deltaLonRad / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Calculate bearing between two GPS coordinates
  static double calculateBearing(LatLng start, LatLng end) {
    double lat1Rad = _degreesToRadians(start.latitude);
    double lat2Rad = _degreesToRadians(end.latitude);
    double deltaLonRad = _degreesToRadians(end.longitude - start.longitude);

    double y = sin(deltaLonRad) * cos(lat2Rad);
    double x =
        cos(lat1Rad) * sin(lat2Rad) -
        sin(lat1Rad) * cos(lat2Rad) * cos(deltaLonRad);

    double bearing = atan2(y, x);
    return _radiansToDegrees(bearing);
  }

  /// Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Convert radians to degrees
  static double _radiansToDegrees(double radians) {
    return radians * (180 / pi);
  }

  /// Request necessary permissions
  static Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.location,
    ].request();

    return statuses[Permission.camera]!.isGranted &&
        statuses[Permission.location]!.isGranted;
  }

  /// Get current device location
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }
}
