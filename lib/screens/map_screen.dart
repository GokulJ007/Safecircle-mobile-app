import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../core/constants/app_colors.dart';
import '../services/location_service.dart';

/// A premium, reusable Map Screen to verify Google Maps rendering and interaction.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;

  // Default coordinate: Chennai (fallback if GPS fails or permission denied)
  static const LatLng _defaultLocation = LatLng(13.0827, 80.2707);

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: _defaultLocation,
    zoom: 13.0,
  );

  late final Set<Marker> _markers;

  // Location-related states
  Position? _currentPosition;
  bool _isLoading = true;
  String? _errorMessage;
  LocationPermission _permissionState = LocationPermission.denied;
  bool _serviceEnabled = false;

  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _markers = {
      Marker(
        markerId: const MarkerId('chennai_default_marker'),
        position: _defaultLocation,
        infoWindow: const InfoWindow(
          title: 'Chennai Center',
          snippet: 'SafeCircle Initial Map Integration Test (Fallback)',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };
    _initLocation();
  }

  Future<void> _initLocation() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final hasService = await LocationService.instance.isServiceEnabled();
      if (!mounted) return;
      setState(() {
        _serviceEnabled = hasService;
      });

      if (!hasService) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Location services are disabled on your device. Please enable them to use location tracking.';
        });
        return;
      }

      final permission = await LocationService.instance.handlePermission();
      if (!mounted) return;
      setState(() {
        _permissionState = permission;
      });

      if (permission == LocationPermission.denied) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Location permission denied. Please grant permission to see your current location.';
        });
        return;
      } else if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Location permission permanently denied. Please enable it in your device/app settings.';
        });
        return;
      }

      // Permission is granted (coarse or fine)
      final position = await LocationService.instance.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });

      // Move camera to current position if map controller is available
      _moveToPosition(position);

      // Start listening to updates
      _startLocationUpdates();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to obtain GPS location: ${e.toString()}';
      });
    }
  }

  void _startLocationUpdates() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = LocationService.instance.getPositionStream().listen(
      (Position position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });
        }
      },
      onError: (error) {
        debugPrint('Location stream error: $error');
      },
    );
  }

  void _moveToPosition(Position position) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15.0,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Set<Marker> get _mapMarkers {
    final markers = Set<Marker>.from(_markers);
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location_marker'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          infoWindow: InfoWindow(
            title: 'Your Location',
            snippet: 'Lat: ${_currentPosition!.latitude.toStringAsFixed(5)}, Lng: ${_currentPosition!.longitude.toStringAsFixed(5)}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final hasLocationPermission = _permissionState == LocationPermission.whileInUse ||
        _permissionState == LocationPermission.always;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SafeCircle Map',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            markers: _mapMarkers,
            mapType: MapType.normal,
            myLocationEnabled: hasLocationPermission,
            myLocationButtonEnabled: false, // Disabling built-in button to use custom FAB
            zoomControlsEnabled: true,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            rotateGesturesEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              if (_currentPosition != null) {
                _moveToPosition(_currentPosition!);
              }
            },
          ),
          // Info Banner Card
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white.withOpacity(0.95),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    Icon(
                      _errorMessage != null
                          ? Icons.error_outline_rounded
                          : Icons.gps_fixed_rounded,
                      color: _errorMessage != null ? Colors.red : AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _errorMessage != null ? 'Location Status' : 'GPS Tracking Active',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _errorMessage != null ? Colors.red.shade800 : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _errorMessage ?? 'Displaying real-time device coordinates on the map.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (!_serviceEnabled)
                                  TextButton(
                                    onPressed: () async {
                                      await LocationService.instance.openLocationSettings();
                                      _initLocation();
                                    },
                                    child: const Text('Enable Services'),
                                  )
                                else if (_permissionState == LocationPermission.deniedForever)
                                  TextButton(
                                    onPressed: () async {
                                      await LocationService.instance.openAppSettings();
                                      _initLocation();
                                    },
                                    child: const Text('Open App Settings'),
                                  )
                                else
                                  TextButton(
                                    onPressed: _initLocation,
                                    child: const Text('Grant Permission / Retry'),
                                  ),
                              ],
                            )
                          ]
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Developer/Testing coordinate overlay display at bottom-left
          if (_currentPosition != null)
            Positioned(
              bottom: 16,
              left: 16,
              child: Card(
                elevation: 4,
                color: Colors.black.withOpacity(0.75),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Latitude: ${_currentPosition!.latitude.toStringAsFixed(5)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Longitude: ${_currentPosition!.longitude.toStringAsFixed(5)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Custom "My Location" floating action button
          if (hasLocationPermission)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: () {
                  if (_currentPosition != null) {
                    _moveToPosition(_currentPosition!);
                  } else {
                    _initLocation();
                  }
                },
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.my_location_rounded, color: Colors.white),
              ),
            ),
          // Location loading state
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Acquiring GPS Signal...',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Please ensure location services are enabled',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
