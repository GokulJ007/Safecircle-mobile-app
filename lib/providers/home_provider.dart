import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/journey_model.dart';
import '../models/contact_model.dart';
import '../services/location_service.dart';
import '../services/journey_service.dart';
import '../services/route_service.dart';

/// Supplies dashboard state and coordinates real GPS-based live tracking sessions.
class HomeProvider extends ChangeNotifier {
  Timer? _simulationTimer;

  // Active Journey state
  bool _hasActiveJourney = false;
  String _activeDestination = '';
  String _activeEta = '';
  String? _activeNotes;
  List<String> _activeSharedContactIds = [];
  DateTime? _activeStartTime;
  int _activeBattery = 82; // Reset battery level to 82% as required
  int _journeySecondsElapsed = 0;
  bool _showSmartCheckIn = false;

  // Real GPS live tracking fields
  String? _activeJourneyId;
  double? _currentLatitude;
  double? _currentLongitude;
  double? _destinationLatitude;
  double? _destinationLongitude;
  String _remainingDistance = 'Calculating...';
  String _activeStatus = 'idle'; // idle, starting, active, ending, completed, error
  String? _errorMessage;
  List<LatLng> _activePolylinePoints = [];

  StreamSubscription<Position>? _positionSubscription;
  DateTime? _lastRouteRecalculationTime;
  Position? _lastRouteRecalculationPosition;

  // Contacts state
  final List<ContactModel> _contacts = [
    const ContactModel(
      id: 'c1',
      name: 'Mom',
      phone: '+91 98765 43210',
      relationship: 'Mother',
    ),
    const ContactModel(
      id: 'c2',
      name: 'Dad',
      phone: '+91 87654 32109',
      relationship: 'Father',
    ),
    const ContactModel(
      id: 'c3',
      name: 'Friend (Gokul)',
      phone: '+91 76543 21098',
      relationship: 'Friend',
    ),
    const ContactModel(
      id: 'c4',
      name: 'Boss',
      phone: '+91 65432 10987',
      relationship: 'Work',
    ),
  ];

  // Journey history logs
  final List<JourneyModel> _recentJourneys = [
    JourneyModel(
      id: 'j1',
      destination: 'Home from Downtown Office',
      dateTime: DateTime.now().subtract(const Duration(hours: 5)),
      duration: '28 min',
      distanceKm: 8.5,
      status: JourneyStatus.completed,
      eta: '5:30 PM',
      notes: 'Car pool with colleagues',
      sharedContactIds: ['c1', 'c2'],
      startBattery: 90,
      endBattery: 85,
    ),
    JourneyModel(
      id: 'j2',
      destination: 'Riverside Mall',
      dateTime: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      duration: '15 min',
      distanceKm: 4.2,
      status: JourneyStatus.completed,
      eta: '2:15 PM',
      sharedContactIds: ['c3'],
      startBattery: 78,
      endBattery: 75,
    ),
    JourneyModel(
      id: 'j3',
      destination: 'Night Walk - Elm Street',
      dateTime: DateTime.now().subtract(const Duration(days: 2, hours: 6)),
      duration: '12 min',
      distanceKm: 1.1,
      status: JourneyStatus.cancelled,
      eta: '10:45 PM',
      notes: 'Cancelled due to rain',
      sharedContactIds: ['c1'],
      startBattery: 45,
      endBattery: 44,
    ),
  ];

  // Getters
  bool get hasActiveJourney => _hasActiveJourney;
  String get activeDestination => _activeDestination;
  String get activeEta => _activeEta;
  String? get activeNotes => _activeNotes;
  List<String> get activeSharedContactIds => _activeSharedContactIds;
  DateTime? get activeStartTime => _activeStartTime;
  int get activeBattery => _activeBattery;
  int get journeySecondsElapsed => _journeySecondsElapsed;
  bool get showSmartCheckIn => _showSmartCheckIn;

  String? get activeJourneyId => _activeJourneyId;
  double? get currentLatitude => _currentLatitude;
  double? get currentLongitude => _currentLongitude;
  double? get destinationLatitude => _destinationLatitude;
  double? get destinationLongitude => _destinationLongitude;
  String get remainingDistance => _remainingDistance;
  String get activeStatus => _activeStatus;
  String? get errorMessage => _errorMessage;
  List<LatLng> get activePolylinePoints => _activePolylinePoints;

  List<ContactModel> get contacts => List.unmodifiable(_contacts);
  List<JourneyModel> get recentJourneys => List.unmodifiable(_recentJourneys);

  // Dynamic statistics for dashboard
  int get trustedContactsCount => _contacts.length;
  
  int get journeysToday {
    final today = DateTime.now();
    return _recentJourneys.where((j) =>
      j.dateTime.year == today.year &&
      j.dateTime.month == today.month &&
      j.dateTime.day == today.day
    ).length;
  }

  double get totalDistanceKm {
    return _recentJourneys
        .where((j) => j.status == JourneyStatus.completed)
        .fold(0.0, (sum, j) => sum + j.distanceKm);
  }

  // Active tracking formatters
  String get formattedDuration {
    final minutes = _journeySecondsElapsed ~/ 60;
    final seconds = _journeySecondsElapsed % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Contact CRUD Operations
  void addContact(String name, String phone, String relationship) {
    final newContact = ContactModel(
      id: 'c-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: phone,
      relationship: relationship,
    );
    _contacts.add(newContact);
    notifyListeners();
  }

  void updateContact(String id, String name, String phone, String relationship) {
    final index = _contacts.indexWhere((c) => c.id == id);
    if (index != -1) {
      _contacts[index] = ContactModel(
        id: id,
        name: name,
        phone: phone,
        relationship: relationship,
      );
      notifyListeners();
    }
  }

  void deleteContact(String id) {
    _contacts.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  // Real Journey Operations
  Future<bool> startNewJourney({
    required String destination,
    required double destLatitude,
    required double destLongitude,
    required double startLatitude,
    required double startLongitude,
    required String eta,
    required DateTime etaDateTime,
    String? notes,
    required List<String> contactIds,
    required String authToken,
    required List<LatLng> initialPolylinePoints,
    required String initialDistance,
  }) async {
    if (_hasActiveJourney) return false;

    _activeStatus = 'starting';
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await JourneyService.instance.startJourney(
        destinationName: destination,
        destinationLatitude: destLatitude,
        destinationLongitude: destLongitude,
        eta: etaDateTime,
        authToken: authToken,
      );

      _activeJourneyId = response['id'] as String;
      _hasActiveJourney = true;
      _activeDestination = destination;
      _destinationLatitude = destLatitude;
      _destinationLongitude = destLongitude;
      _currentLatitude = startLatitude;
      _currentLongitude = startLongitude;
      _activeEta = eta;
      _activeNotes = notes;
      _activeSharedContactIds = contactIds;
      _activeStartTime = DateTime.now();
      _activeBattery = 82; // Reset battery level to 82% as required
      _journeySecondsElapsed = 0;
      _showSmartCheckIn = false;
      _activePolylinePoints = initialPolylinePoints;
      _remainingDistance = initialDistance;
      _activeStatus = 'active';

      // Start elapsed timer
      _simulationTimer?.cancel();
      _simulationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _journeySecondsElapsed++;
        if (_journeySecondsElapsed == 15) {
          _showSmartCheckIn = true;
        }
        notifyListeners();
      });

      // Start GPS listening
      _startGpsSubscription(authToken);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("startNewJourney error: $e");
      _activeStatus = 'error';
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _startGpsSubscription(String authToken) {
    _positionSubscription?.cancel();
    _lastRouteRecalculationPosition = null;
    _lastRouteRecalculationTime = null;

    _positionSubscription = LocationService.instance.getPositionStream(distanceFilter: 5).listen(
      (Position position) {
        _handleLocationUpdate(position, authToken);
      },
      onError: (error) {
        debugPrint("Location stream error: $error");
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  Future<void> _handleLocationUpdate(Position position, String authToken) async {
    if (!_hasActiveJourney || _activeJourneyId == null) return;

    _currentLatitude = position.latitude;
    _currentLongitude = position.longitude;
    notifyListeners();

    try {
      await JourneyService.instance.updateLocation(
        journeyId: _activeJourneyId!,
        latitude: position.latitude,
        longitude: position.longitude,
        batteryPercentage: _activeBattery.toDouble(),
        authToken: authToken,
      );
    } catch (e) {
      debugPrint("Failed to send location update to backend: $e");
    }

    double distanceMoved = 0.0;
    if (_lastRouteRecalculationPosition != null) {
      distanceMoved = Geolocator.distanceBetween(
        _lastRouteRecalculationPosition!.latitude,
        _lastRouteRecalculationPosition!.longitude,
        position.latitude,
        position.longitude,
      );
    }

    final now = DateTime.now();
    final timeElapsed = _lastRouteRecalculationTime == null
        ? const Duration(minutes: 999)
        : now.difference(_lastRouteRecalculationTime!);

    if (_lastRouteRecalculationPosition == null || distanceMoved > 30 || timeElapsed.inSeconds > 60) {
      _lastRouteRecalculationPosition = position;
      _lastRouteRecalculationTime = now;
      _recalculateRouteAndETA(position.latitude, position.longitude);
    }
  }

  Future<void> _recalculateRouteAndETA(double lat, double lng) async {
    if (_destinationLatitude == null || _destinationLongitude == null) return;

    try {
      final origin = LatLng(lat, lng);
      final destination = LatLng(_destinationLatitude!, _destinationLongitude!);

      final routeResult = await RouteService.instance.calculateRoute(
        origin: origin,
        destination: destination,
      );

      _activePolylinePoints = routeResult.polylinePoints;
      _remainingDistance = routeResult.distance;
      
      final now = DateTime.now();
      final etaTime = now.add(Duration(seconds: routeResult.durationSeconds));
      final hour = etaTime.hour > 12 ? etaTime.hour - 12 : (etaTime.hour == 0 ? 12 : etaTime.hour);
      final minute = etaTime.minute.toString().padLeft(2, '0');
      final period = etaTime.hour >= 12 ? 'PM' : 'AM';
      _activeEta = '$hour:$minute $period';
      
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to recalculate route in background: $e");
    }
  }

  void dismissSmartCheckIn() {
    _showSmartCheckIn = false;
    notifyListeners();
  }

  Future<bool> endCurrentJourney(JourneyStatus finalStatus, String authToken) async {
    if (!_hasActiveJourney || _activeJourneyId == null) return false;

    _activeStatus = 'ending';
    notifyListeners();

    try {
      await JourneyService.instance.endJourney(
        journeyId: _activeJourneyId!,
        authToken: authToken,
      );

      _positionSubscription?.cancel();
      _positionSubscription = null;
      _simulationTimer?.cancel();
      _simulationTimer = null;

      final elapsedMin = (_journeySecondsElapsed / 60).ceil();
      final elapsedLabel = elapsedMin <= 0 ? '1 min' : '$elapsedMin min';
      
      final completedJourney = JourneyModel(
        id: _activeJourneyId!,
        destination: _activeDestination,
        dateTime: _activeStartTime ?? DateTime.now(),
        duration: elapsedLabel,
        distanceKm: double.tryParse(_remainingDistance.replaceAll(' km', '')) ?? 1.2,
        status: finalStatus,
        eta: _activeEta,
        notes: _activeNotes,
        sharedContactIds: List.from(_activeSharedContactIds),
        startBattery: _activeBattery,
        endBattery: _activeBattery - 2,
      );

      _recentJourneys.insert(0, completedJourney);

      // Reset active journey state
      _hasActiveJourney = false;
      _activeJourneyId = null;
      _activeDestination = '';
      _activeEta = '';
      _activeNotes = null;
      _activeSharedContactIds = [];
      _activeStartTime = null;
      _journeySecondsElapsed = 0;
      _showSmartCheckIn = false;
      _currentLatitude = null;
      _currentLongitude = null;
      _destinationLatitude = null;
      _destinationLongitude = null;
      _activePolylinePoints = [];
      _remainingDistance = 'Calculating...';
      _activeStatus = 'idle';

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Failed to end journey: $e");
      _activeStatus = 'error';
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }
}