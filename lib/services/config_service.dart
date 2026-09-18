import 'package:flutter/services.dart';

/// ConfigService retrieves environment and build configurations from the native host.
class ConfigService {
  ConfigService._();

  static const String backendBaseUrl = "http://192.168.0.2:8000";

  static const MethodChannel _channel = MethodChannel('com.example.safecircle/config');

  /// Fetches the Google Maps/Places API key defined in local.properties -> AndroidManifest.xml metadata.
  static Future<String?> getApiKey() async {
    try {
      final String? apiKey = await _channel.invokeMethod<String>('getApiKey');
      return apiKey;
    } on PlatformException catch (e) {
      // Return null and log. In production, log via a custom logger.
      print("SafeCircle ConfigService: Failed to retrieve API key: '${e.message}'");
      return null;
    }
  }
}
