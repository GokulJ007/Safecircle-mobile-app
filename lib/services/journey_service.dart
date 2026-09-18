import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config_service.dart';

/// Service class interfacing with SafeCircle backend for journey operations.
class JourneyService {
  JourneyService._();

  static final JourneyService instance = JourneyService._();

  /// Starts a new journey on the backend.
  Future<Map<String, dynamic>> startJourney({
    required String destinationName,
    required double destinationLatitude,
    required double destinationLongitude,
    required DateTime eta,
    required String authToken,
  }) async {
    final url = Uri.parse('${ConfigService.backendBaseUrl}/journeys/start');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $authToken',
    };
    final body = jsonEncode({
      'destination_name': destinationName,
      'destination_latitude': destinationLatitude,
      'destination_longitude': destinationLongitude,
      'eta': eta.toUtc().toIso8601String(),
    });

    final response = await http.post(url, headers: headers, body: body).timeout(
      const Duration(seconds: 15),
    );

    if (response.statusCode != 201) {
      throw Exception("Failed to start journey (${response.statusCode}): ${response.body}");
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Sends the user's updated location to the backend.
  Future<void> updateLocation({
    required String journeyId,
    required double latitude,
    required double longitude,
    required double batteryPercentage,
    required String authToken,
  }) async {
    final url = Uri.parse('${ConfigService.backendBaseUrl}/journeys/$journeyId/location');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $authToken',
    };
    final body = jsonEncode({
      'latitude': latitude,
      'longitude': longitude,
      'battery_percentage': batteryPercentage,
    });

    final response = await http.put(url, headers: headers, body: body).timeout(
      const Duration(seconds: 15),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update location (${response.statusCode}): ${response.body}");
    }
  }

  /// Ends an active journey on the backend.
  Future<Map<String, dynamic>> endJourney({
    required String journeyId,
    required String authToken,
  }) async {
    final url = Uri.parse('${ConfigService.backendBaseUrl}/journeys/$journeyId/end');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $authToken',
    };

    final response = await http.put(url, headers: headers).timeout(
      const Duration(seconds: 15),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to end journey (${response.statusCode}): ${response.body}");
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
