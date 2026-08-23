import 'dart:async';
import 'package:flutter/material.dart';
import '../models/journey_model.dart';
import '../models/contact_model.dart';

/// Supplies mock dashboard and live journey simulation state.
class HomeProvider extends ChangeNotifier {
  Timer? _simulationTimer;

  // Active Journey state
  bool _hasActiveJourney = false;
  String _activeDestination = '';
  String _activeEta = '';
  String? _activeNotes;
  List<String> _activeSharedContactIds = [];
  DateTime? _activeStartTime;
  int _activeBattery = 82; // Mock battery level as specified
  int _journeySecondsElapsed = 0;
  bool _showSmartCheckIn = false;

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

  // Journey Operations
  void startNewJourney({
    required String destination,
    required String eta,
    String? notes,
    required List<String> contactIds,
  }) {
    if (_hasActiveJourney) return;

    _hasActiveJourney = true;
    _activeDestination = destination;
    _activeEta = eta;
    _activeNotes = notes;
    _activeSharedContactIds = contactIds;
    _activeStartTime = DateTime.now();
    _activeBattery = 82; // Reset battery level to 82% as required
    _journeySecondsElapsed = 0;
    _showSmartCheckIn = false;

    // Start Simulation Timer
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _journeySecondsElapsed++;
      // Auto-trigger check-in alert at 15 seconds to demonstrate Smart Check-In
      if (_journeySecondsElapsed == 15) {
        _showSmartCheckIn = true;
      }
      notifyListeners();
    });

    notifyListeners();
  }

  void dismissSmartCheckIn() {
    _showSmartCheckIn = false;
    notifyListeners();
  }

  void endCurrentJourney(JourneyStatus finalStatus) {
    if (!_hasActiveJourney) return;

    _simulationTimer?.cancel();
    _simulationTimer = null;

    final elapsedMin = (_journeySecondsElapsed / 60).ceil();
    final elapsedLabel = elapsedMin <= 0 ? '1 min' : '$elapsedMin min';
    
    // Add simulated completed trip to history
    final completedJourney = JourneyModel(
      id: 'j-${DateTime.now().millisecondsSinceEpoch}',
      destination: _activeDestination,
      dateTime: _activeStartTime ?? DateTime.now(),
      duration: elapsedLabel,
      distanceKm: double.parse((0.1 * (_journeySecondsElapsed / 10) + 1.2).toStringAsFixed(1)), // mock distance
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
    _activeDestination = '';
    _activeEta = '';
    _activeNotes = null;
    _activeSharedContactIds = [];
    _activeStartTime = null;
    _journeySecondsElapsed = 0;
    _showSmartCheckIn = false;

    notifyListeners();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }
}