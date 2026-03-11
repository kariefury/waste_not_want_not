import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Privacy-first location service.
///
/// Design principles:
/// • Exact coordinates are NEVER shared with other users.
/// • Positions are snapped to a neighbourhood-level grid before
///   being used in queries or stored on any server.
/// • Users choose their own pickup address — the app doesn't
///   auto-reveal their home location.
class LocationService {
  static const double _gridSizeKm = 0.5; // ~500 m grid cells

  /// Request location permission and return the current position.
  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException('Location permission denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'Location permissions are permanently denied. '
            'Please enable them in Settings.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low, // neighbourhood-level is enough
      ),
    );
  }

  /// Snap a coordinate to the privacy grid so exact locations
  /// are never transmitted or stored.
  static ({double lat, double lng}) snapToGrid(double lat, double lng) {
    const double kmPerDegreeLat = 111.0;
    final double kmPerDegreeLng = 111.0 * cos(lat * pi / 180);

    final double latStep = _gridSizeKm / kmPerDegreeLat;
    final double lngStep = _gridSizeKm / kmPerDegreeLng;

    return (
    lat: (lat / latStep).roundToDouble() * latStep,
    lng: (lng / lngStep).roundToDouble() * lngStep,
    );
  }

  /// Haversine distance in kilometres.
  static double distanceKm(
      double lat1, double lng1,
      double lat2, double lng2,
      ) {
    const R = 6371.0; // earth radius km
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  /// Human-friendly distance label.
  static String distanceLabel(double km) {
    if (km < 0.2) return 'A short walk';
    if (km < 1) return '${(km * 1000).round()} m away';
    if (km < 10) return '${km.toStringAsFixed(1)} km away';
    return '${km.round()} km away';
  }

  /// Reverse-geocode to a neighbourhood / city name.
  static Future<String> getNeighbourhoodName(
      double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [p.subLocality, p.locality]
            .where((s) => s != null && s.isNotEmpty);
        if (parts.isNotEmpty) return parts.join(', ');
      }
    } catch (_) {}
    return 'Your neighbourhood';
  }

  static double _rad(double deg) => deg * pi / 180;
}

class LocationException implements Exception {
  LocationException(this.message);
  final String message;
  @override
  String toString() => message;
}