import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'config_service.dart';

/// The result returned from calculating a route.
class RouteResult {
  final List<LatLng> polylinePoints;
  final String duration;
  final String distance;
  final int durationSeconds;
  final int distanceMeters;

  RouteResult({
    required this.polylinePoints,
    required this.duration,
    required this.distance,
    required this.durationSeconds,
    required this.distanceMeters,
  });
}

/// Service class interfacing with SafeCircle backend for route calculation.
class RouteService {
  RouteService._();

  static final RouteService instance = RouteService._();

  // Local development host Wi-Fi IP address pointing to local FastAPI backend
  static const String _backendBaseUrl = ConfigService.backendBaseUrl;

  /// Calculates a route between [origin] and [destination] by invoking the backend routes endpoint.
  Future<RouteResult> calculateRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final url = Uri.parse('$_backendBaseUrl/routes/calculate');
    final headers = {
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'origin_latitude': origin.latitude,
      'origin_longitude': origin.longitude,
      'destination_latitude': destination.latitude,
      'destination_longitude': destination.longitude,
    });

    try {
      final response = await http.post(url, headers: headers, body: body).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode != 200) {
        throw Exception("Backend Route calculation failed (${response.statusCode}): ${response.body}");
      }

      final data = jsonDecode(response.body);
      final distanceMeters = data['distance_meters'] as int? ?? 0;
      final durationSeconds = data['duration_seconds'] as int? ?? 0;
      final durationText = data['duration_text'] as String? ?? '0 min';
      final distanceText = data['distance_text'] as String? ?? '0.0 km';
      final encodedPolyline = data['polyline'] as String?;

      if (encodedPolyline == null) {
        throw Exception("Backend did not return route geometry.");
      }

      final points = _decodePolyline(encodedPolyline);

      return RouteResult(
        polylinePoints: points,
        duration: durationText,
        distance: distanceText,
        durationSeconds: durationSeconds,
        distanceMeters: distanceMeters,
      );
    } catch (e) {
      print("RouteService error: $e");
      rethrow;
    }
  }

  /// Decodes an encoded polyline string from Google Maps API into `List<LatLng>`.
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }
}

