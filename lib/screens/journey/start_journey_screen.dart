import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/home_provider.dart';
import '../../widgets/primary_button.dart';
import '../../models/place_model.dart';
import '../../services/location_service.dart';
import '../../services/route_service.dart';
import 'place_search_screen.dart';

class StartJourneyScreen extends StatefulWidget {
  const StartJourneyScreen({super.key});

  @override
  State<StartJourneyScreen> createState() => _StartJourneyScreenState();
}

class _StartJourneyScreenState extends State<StartJourneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _destinationController = TextEditingController();
  final _notesController = TextEditingController(text: 'Heading to destination with SafeCircle tracking');
  String _selectedEtaText = 'Calculating...';

  final Set<String> _selectedContactIds = {};

  // GPS and Route states
  Position? _currentLocation;
  bool _isLocationLoading = true;
  String? _locationError;
  SafeCirclePlace? _selectedPlace;

  RouteResult? _routeResult;
  bool _isRouteLoading = false;
  String? _routeError;

  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    // Default select all contacts for safety
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    for (var c in homeProvider.contacts) {
      _selectedContactIds.add(c.id);
    }
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _notesController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    if (!mounted) return;
    setState(() {
      _isLocationLoading = true;
      _locationError = null;
    });

    try {
      final permission = await LocationService.instance.handlePermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() {
          _isLocationLoading = false;
          _locationError = "Location permission denied. Please grant location access in settings.";
        });
        return;
      }

      final position = await LocationService.instance.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _currentLocation = position;
        _isLocationLoading = false;
      });

      // If destination was already selected, recalculate route
      if (_selectedPlace != null) {
        _calculateRoute();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLocationLoading = false;
        _locationError = "Failed to obtain current GPS: ${e.toString()}";
      });
    }
  }

  Future<void> _calculateRoute() async {
    if (_currentLocation == null || _selectedPlace == null) return;

    if (!mounted) return;
    setState(() {
      _isRouteLoading = true;
      _routeError = null;
    });

    try {
      final origin = LatLng(_currentLocation!.latitude, _currentLocation!.longitude);
      final dest = LatLng(_selectedPlace!.latitude, _selectedPlace!.longitude);

      final routeResult = await RouteService.instance.calculateRoute(
        origin: origin,
        destination: dest,
      );

      if (!mounted) return;
      setState(() {
        _routeResult = routeResult;
        _isRouteLoading = false;
        
        // Auto-calculate expected arrival time
        final now = DateTime.now();
        final etaTime = now.add(Duration(seconds: routeResult.durationSeconds));
        _selectedEtaText = TimeOfDay.fromDateTime(etaTime).format(context);
      });

      _fitMapBounds();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _routeError = "Failed to calculate route: ${e.toString()}";
        _isRouteLoading = false;
        _selectedEtaText = "Error calculating ETA";
      });
    }
  }

  void _fitMapBounds() {
    if (_mapController == null || _currentLocation == null || _selectedPlace == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mapController == null) return;
      final bounds = _boundsFromLatLngs(
        LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
        LatLng(_selectedPlace!.latitude, _selectedPlace!.longitude),
      );
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50.0),
      );
    });
  }

  LatLngBounds _boundsFromLatLngs(LatLng p1, LatLng p2) {
    double southwestLat = p1.latitude < p2.latitude ? p1.latitude : p2.latitude;
    double southwestLng = p1.longitude < p2.longitude ? p1.longitude : p2.longitude;
    double northeastLat = p1.latitude > p2.latitude ? p1.latitude : p2.latitude;
    double northeastLng = p1.longitude > p2.longitude ? p1.longitude : p2.longitude;

    return LatLngBounds(
      southwest: LatLng(southwestLat, southwestLng),
      northeast: LatLng(northeastLat, northeastLng),
    );
  }

  Set<Marker> _getMapMarkers() {
    final markers = <Marker>{};
    if (_currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_pos'),
          position: LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
    if (_selectedPlace != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination_pos'),
          position: LatLng(_selectedPlace!.latitude, _selectedPlace!.longitude),
          infoWindow: InfoWindow(title: _selectedPlace!.name, snippet: _selectedPlace!.address),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
    return markers;
  }

  Set<Polyline> _getMapPolylines() {
    final polylines = <Polyline>{};
    if (_routeResult != null) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route_line'),
          points: _routeResult!.polylinePoints,
          color: AppColors.primary,
          width: 5,
        ),
      );
    }
    return polylines;
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 17, minute: 45),
    );
    if (picked != null) {
      if (!mounted) return;
      setState(() {
        _selectedEtaText = picked.format(context);
      });
    }
  }

  void _handleStartJourney() {
    if (!_formKey.currentState!.validate()) return;
    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot start journey without GPS location. Please wait or retry.'),
          backgroundColor: AppColors.sosRed,
        ),
      );
      return;
    }
    if (_selectedContactIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one contact to share your journey with.'),
          backgroundColor: AppColors.warningOrange,
        ),
      );
      return;
    }

    final destinationName = _destinationController.text.trim();
    final eta = _selectedEtaText;

    // Log the unified data structure as required
    debugPrint("=== SAFE CIRCLE JOURNEY CONFIRMATION ===");
    debugPrint("Destination: $destinationName");
    debugPrint("Destination Latitude: ${_selectedPlace?.latitude}");
    debugPrint("Destination Longitude: ${_selectedPlace?.longitude}");
    debugPrint("Current Latitude: ${_currentLocation!.latitude}");
    debugPrint("Current Longitude: ${_currentLocation!.longitude}");
    debugPrint("ETA: $eta");
    debugPrint("Distance: ${_routeResult?.distance ?? 'Unknown'}");
    debugPrint("Shared Contacts: ${_selectedContactIds.toList()}");
    debugPrint("=========================================");

    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    homeProvider.startNewJourney(
      destination: destinationName,
      eta: eta,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      contactIds: _selectedContactIds.toList(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Journey started to $destinationName (ETA: $eta)"),
        backgroundColor: AppColors.safeGreen,
      ),
    );

    // Redirect to active journey screen
    context.pushReplacement('/journey');
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();
    final contacts = homeProvider.contacts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Start Safe Journey', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF9FBFF), Color(0xFFF4F8FF), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Embedded Map Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: Colors.blueGrey.shade50),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SizedBox(
                      height: 240,
                      child: Stack(
                        children: [
                          if (_isLocationLoading)
                            const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 12),
                                  Text("Fetching GPS location..."),
                                ],
                              ),
                            )
                          else if (_locationError != null)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.location_off_rounded, color: AppColors.sosRed),
                                    const SizedBox(height: 8),
                                    Text(_locationError!, textAlign: TextAlign.center),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: _fetchCurrentLocation,
                                      child: const Text("Retry GPS"),
                                    )
                                  ],
                                ),
                              ),
                            )
                          else
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
                                zoom: 14.0,
                              ),
                              markers: _getMapMarkers(),
                              polylines: _getMapPolylines(),
                              myLocationEnabled: true,
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: false,
                              scrollGesturesEnabled: true,
                              zoomGesturesEnabled: true,
                              onMapCreated: (controller) {
                                _mapController = controller;
                                if (_selectedPlace != null) {
                                  _fitMapBounds();
                                }
                              },
                            ),
                          if (_isRouteLoading)
                            Container(
                              color: Colors.black.withOpacity(0.3),
                              child: const Center(
                                child: Card(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(),
                                        SizedBox(width: 16),
                                        Text("Calculating route...", style: TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Route Details Card
                  if (_routeResult != null) ...[
                    Card(
                      elevation: 0,
                      color: AppColors.primary.withOpacity(0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text("Estimated Time", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                const SizedBox(height: 4),
                                Text(_routeResult!.duration, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                              ],
                            ),
                            Container(height: 30, width: 1.5, color: Colors.blueGrey.shade100),
                            Column(
                              children: [
                                const Text("Total Distance", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                const SizedBox(height: 4),
                                Text(_routeResult!.distance, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (_routeError != null) ...[
                    Card(
                      elevation: 0,
                      color: AppColors.sosRed.withOpacity(0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: AppColors.sosRed.withOpacity(0.24)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.sosRed),
                            const SizedBox(height: 8),
                            Text(
                              _routeError!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _calculateRoute,
                              child: const Text("Retry Route Calculation"),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  Card(
                    elevation: 0,
                    color: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: Colors.blueGrey.shade50),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Destination & Arrival Details',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _destinationController,
                            readOnly: true,
                            onTap: () async {
                              final result = await Navigator.of(context).push<SafeCirclePlace>(
                                MaterialPageRoute(builder: (context) => const PlaceSearchScreen()),
                              );
                              if (result != null) {
                                setState(() {
                                  _selectedPlace = result;
                                  _destinationController.text = result.name;
                                });
                                _calculateRoute();
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'Destination Place',
                              hintText: 'Tap to select destination...',
                              prefixIcon: const Icon(Icons.location_on_outlined),
                              suffixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            validator: (value) => value == null || value.trim().isEmpty ? 'Please select a destination' : null,
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () => _selectTime(context),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, color: AppColors.textSecondary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Expected Time of Arrival (ETA)', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                        const SizedBox(height: 4),
                                        Text(
                                          _selectedEtaText,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down_rounded),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _notesController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'Journey Notes (optional)',
                              prefixIcon: const Icon(Icons.edit_note_rounded),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 0,
                    color: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: Colors.blueGrey.shade50),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Circle Guardians',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Selected contacts will receive mock pings and location coordinates.',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          contacts.isEmpty
                              ? _buildEmptyContactsWarning()
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: contacts.length,
                                  separatorBuilder: (context, index) => const Divider(),
                                  itemBuilder: (context, index) {
                                    final contact = contacts[index];
                                    final isSelected = _selectedContactIds.contains(contact.id);
                                    return CheckboxListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('${contact.relationship} • ${contact.phone}'),
                                      value: isSelected,
                                      activeColor: AppColors.primary,
                                      onChanged: (checked) {
                                        setState(() {
                                          if (checked == true) {
                                            _selectedContactIds.add(contact.id);
                                          } else {
                                            _selectedContactIds.remove(contact.id);
                                          }
                                        });
                                      },
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: 'Start Live Tracking',
                    onPressed: _handleStartJourney,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyContactsWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningOrange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warningOrange.withOpacity(0.24)),
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warningOrange, size: 28),
          const SizedBox(height: 8),
          const Text(
            'Your trusted circle is empty!',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Go back to the Contacts tab to add trusted members before starting a safe journey.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              context.pop();
            },
            child: const Text('Back to Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
