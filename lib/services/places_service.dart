import 'package:google_places_sdk_plus/google_places_sdk_plus.dart';
import 'config_service.dart';

/// Service class interfacing with google_places_sdk_plus library.
class PlacesService {
  PlacesService._();

  static final PlacesService instance = PlacesService._();

  FlutterGooglePlacesSdk? _sdk;
  bool _initialized = false;

  /// Lazy initialization of the Places SDK using MethodChannel key retrieval.
  Future<void> _ensureInitialized() async {
    if (_initialized && _sdk != null) return;

    final apiKey = await ConfigService.getApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      _sdk = FlutterGooglePlacesSdk(apiKey);
      _initialized = true;
    } else {
      throw Exception("PlacesService: Google Maps/Places API key not configured or unavailable.");
    }
  }

  /// Get autocomplete predictions for search queries.
  Future<List<AutocompletePrediction>> findPredictions(String query) async {
    if (query.trim().isEmpty) return [];

    await _ensureInitialized();
    try {
      final response = await _sdk!.findAutocompletePredictions(query);
      return response.predictions;
    } catch (e) {
      print("PlacesService: findAutocompletePredictions error: $e");
      rethrow;
    }
  }

  /// Fetch coordinates and details for a selected place.
  Future<Place?> fetchPlaceDetails(String placeId) async {
    await _ensureInitialized();
    try {
      final response = await _sdk!.fetchPlace(
        placeId,
        fields: [
          PlaceField.Id,
          PlaceField.DisplayName,
          PlaceField.FormattedAddress,
          PlaceField.Location,
        ],
      );
      return response.place;
    } catch (e) {
      print("PlacesService: fetchPlaceDetails error: $e");
      rethrow;
    }
  }
}
