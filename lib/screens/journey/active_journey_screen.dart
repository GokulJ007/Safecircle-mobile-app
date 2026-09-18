import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../models/journey_model.dart';
import '../../providers/home_provider.dart';
import '../../providers/auth_provider.dart';

class ActiveJourneyScreen extends StatefulWidget {
  const ActiveJourneyScreen({super.key});

  @override
  State<ActiveJourneyScreen> createState() => _ActiveJourneyScreenState();
}

class _ActiveJourneyScreenState extends State<ActiveJourneyScreen> {
  GoogleMapController? _mapController;
  bool _followUser = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  bool _isSmartCheckInOpen = false;

  void _showSmartCheckInDialog(HomeProvider provider) {
    if (_isSmartCheckInOpen) return;
    _isSmartCheckInOpen = true;

    // We defer the dialog display using Future.microtask to avoid triggering
    // setState during build.
    Future.microtask(() {
      if (!mounted) {
        _isSmartCheckInOpen = false;
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Warning icon and title in a responsive row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.warningOrange,
                              size: 32,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "You're running late.",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Everything okay?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'SafeCircle has detected your delay. Let your circle know you are safe or trigger emergency help.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            side: const BorderSide(color: AppColors.sosRed, width: 1.5),
                            foregroundColor: AppColors.sosRed,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            provider.dismissSmartCheckIn();
                            // Push immediately to SOS
                            context.push('/sos');
                          },
                          child: const Text(
                            'Need Help',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.sosRed,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            backgroundColor: AppColors.safeGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            provider.dismissSmartCheckIn();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Marked safe. Your circle has been updated."),
                                backgroundColor: AppColors.safeGreen,
                              ),
                            );
                          },
                          child: const Text(
                            "I'm Safe",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ).then((_) {
        _isSmartCheckInOpen = false;
      });
    });
  }

  void _showEndJourneyConfirmation(HomeProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: AppColors.surface,
        title: const Text('Arrived Safely?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('This will complete the journey, stop live coordinate sharing, and log this trip in your history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.safeGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(context); // close confirm dialog

              // Show loading overlay
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final token = authProvider.currentUser?.token ?? '';

              final success = await provider.endCurrentJourney(JourneyStatus.completed, token);
              
              if (mounted) {
                Navigator.pop(context); // Pop loading dialog
              }

              if (success) {
                _showSummaryDialog();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Failed to end journey: ${provider.errorMessage ?? 'Unknown error'}"),
                    backgroundColor: AppColors.sosRed,
                  ),
                );
              }
            },
            child: const Text('Yes, I am Safe'),
          ),
        ],
      ),
    );
  }

  void _showSummaryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: AppColors.surface,
        title: Column(
          children: const [
            Icon(Icons.verified_rounded, color: AppColors.safeGreen, size: 54),
            SizedBox(height: 12),
            Text('Journey Completed!', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Your trusted circle has been notified of your safe arrival. Safe tracking session has ended.',
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(160, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                Navigator.pop(context); // close summary dialog
                context.go('/home'); // return to home shell
              },
              child: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();

    // If check-in is pending, show dialog
    if (homeProvider.showSmartCheckIn) {
      _showSmartCheckInDialog(homeProvider);
    }

    final durationText = homeProvider.formattedDuration;
    final destination = homeProvider.activeDestination.isNotEmpty
        ? homeProvider.activeDestination
        : 'CIT College';
    final eta = homeProvider.activeEta.isNotEmpty ? homeProvider.activeEta : '5:45 PM';

    // Camera follow logic
    if (_followUser && _mapController != null && homeProvider.currentLatitude != null && homeProvider.currentLongitude != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(homeProvider.currentLatitude!, homeProvider.currentLongitude!),
          ),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking Session', style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false, // forces user to use action buttons
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  child: Stack(
                    children: [
                      // Styled Custom Map Placeholder
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade50,
                          borderRadius: BorderRadius.circular(36),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryDark.withOpacity(0.24),
                              blurRadius: 28,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(36),
                          child: Stack(
                            children: [
                              if (homeProvider.currentLatitude == null || homeProvider.currentLongitude == null)
                                const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 12),
                                      Text("Waiting for GPS signal..."),
                                    ],
                                  ),
                                )
                              else
                                GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: LatLng(homeProvider.currentLatitude!, homeProvider.currentLongitude!),
                                    zoom: 15.0,
                                  ),
                                  markers: _getMapMarkers(
                                    homeProvider.currentLatitude,
                                    homeProvider.currentLongitude,
                                    homeProvider.destinationLatitude,
                                    homeProvider.destinationLongitude,
                                    destination,
                                  ),
                                  polylines: _getMapPolylines(homeProvider.activePolylinePoints),
                                  myLocationEnabled: true,
                                  myLocationButtonEnabled: false,
                                  zoomControlsEnabled: false,
                                  scrollGesturesEnabled: true,
                                  zoomGesturesEnabled: true,
                                  onCameraMoveStarted: () {
                                    setState(() {
                                      _followUser = false;
                                    });
                                  },
                                  onMapCreated: (controller) {
                                    _mapController = controller;
                                  },
                                ),
                              if (!_followUser && homeProvider.currentLatitude != null && homeProvider.currentLongitude != null)
                                Positioned(
                                  bottom: 16,
                                  right: 16,
                                  child: FloatingActionButton.small(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    onPressed: () {
                                      setState(() {
                                        _followUser = true;
                                      });
                                      _mapController?.animateCamera(
                                        CameraUpdate.newLatLng(
                                          LatLng(homeProvider.currentLatitude!, homeProvider.currentLongitude!),
                                        ),
                                      );
                                    },
                                    child: const Icon(Icons.my_location_rounded),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 20,
                        left: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    height: 8,
                                    width: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.safeGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'GPS Tracking Active',
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.battery_std_rounded, color: Colors.white, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${homeProvider.activeBattery}%',
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Stats Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Card(
                  elevation: 0,
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                    side: BorderSide(color: Colors.blueGrey.shade50),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.navigation_rounded, color: AppColors.primary),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    destination,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Expected Arrival: $eta',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildLiveStat('Elapsed', durationText, Icons.timer_outlined),
                            _buildLiveStat('Guardians', '${homeProvider.activeSharedContactIds.length}', Icons.shield_outlined),
                            _buildLiveStat('Dist. Left', homeProvider.remainingDistance, Icons.directions_walk_rounded),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Emergency Action Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.call_rounded),
                        label: const Text('Fake Call'),
                        onPressed: () => context.push('/fake-call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warningOrange,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text("I'm Safe"),
                        onPressed: () => _showEndJourneyConfirmation(homeProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.safeGreen,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.emergency_rounded),
                        label: const Text('SOS'),
                        onPressed: () => context.push('/sos'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.sosRed,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }

  Set<Marker> _getMapMarkers(double? currentLat, double? currentLng, double? destLat, double? destLng, String destinationName) {
    final markers = <Marker>{};
    if (currentLat != null && currentLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_pos'),
          position: LatLng(currentLat, currentLng),
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
    if (destLat != null && destLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination_pos'),
          position: LatLng(destLat, destLng),
          infoWindow: InfoWindow(title: destinationName),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
    return markers;
  }

  Set<Polyline> _getMapPolylines(List<LatLng> points) {
    final polylines = <Polyline>{};
    if (points.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('active_route_line'),
          points: points,
          color: AppColors.primary,
          width: 5,
        ),
      );
    }
    return polylines;
  }
}
