import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_places_sdk_plus/google_places_sdk_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../models/place_model.dart';
import '../../services/places_service.dart';

class PlaceSearchScreen extends StatefulWidget {
  const PlaceSearchScreen({super.key});

  @override
  State<PlaceSearchScreen> createState() => _PlaceSearchScreenState();
}

class _PlaceSearchScreenState extends State<PlaceSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  bool _isLoadingPredictions = false;
  bool _isLoadingDetails = false;
  List<AutocompletePrediction> _predictions = [];
  String? _errorMessage;

  SafeCirclePlace? _selectedPlace;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isNotEmpty) {
        _fetchPredictions(query);
      } else {
        setState(() {
          _predictions = [];
          _errorMessage = null;
        });
      }
    });
  }

  Future<void> _fetchPredictions(String query) async {
    setState(() {
      _isLoadingPredictions = true;
      _errorMessage = null;
    });

    try {
      final predictions = await PlacesService.instance.findPredictions(query);
      setState(() {
        _predictions = predictions;
        _isLoadingPredictions = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load suggestions. Please try again.";
        _isLoadingPredictions = false;
      });
    }
  }

  Future<void> _selectPlace(AutocompletePrediction prediction) async {
    final placeId = prediction.placeId;
    if (placeId == null) return;

    // Clear search and predictions lists
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoadingDetails = true;
      _predictions = [];
      _searchController.text = prediction.fullText ?? '';
    });

    try {
      final place = await PlacesService.instance.fetchPlaceDetails(placeId);
      if (place != null && place.latLng != null) {
        setState(() {
          _selectedPlace = SafeCirclePlace(
            placeId: placeId,
            name: place.name ?? place.displayName?.text ?? prediction.primaryText ?? 'Selected Location',
            address: place.address ?? place.shortFormattedAddress ?? prediction.secondaryText ?? 'No address description',
            latitude: place.latLng!.lat,
            longitude: place.latLng!.lng,
          );
          _isLoadingDetails = false;
        });
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Coordinates: ${_selectedPlace!.latitude.toStringAsFixed(5)}, ${_selectedPlace!.longitude.toStringAsFixed(5)}"),
            backgroundColor: AppColors.safeGreen,
          ),
        );
      } else {
        setState(() {
          _errorMessage = "Failed to fetch coordinate details for this location.";
          _isLoadingDetails = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error occurred while fetching place details: $e";
        _isLoadingDetails = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Destination Search',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FBFF), Color(0xFFF4F8FE), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Styled Search Input Card
                    Card(
                      elevation: 0,
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(color: Colors.blueGrey.shade50),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: _onSearchChanged,
                                decoration: const InputDecoration(
                                  hintText: 'Search for a place or address...',
                                  hintStyle: TextStyle(color: AppColors.textSecondary),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Autocomplete predictions list or loading
              Expanded(
                child: Stack(
                  children: [
                    if (_isLoadingPredictions)
                      const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      )
                    else if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.sosRed, fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    else if (_searchController.text.isNotEmpty && _predictions.isEmpty && !_isLoadingDetails)
                      const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(
                          child: Text(
                            'No matching locations found.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _predictions.length,
                        itemBuilder: (context, index) {
                          final prediction = _predictions[index];
                          return Card(
                            elevation: 0,
                            color: Colors.white,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.blueGrey.shade50),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.location_on_outlined, color: AppColors.textSecondary),
                              title: Text(
                                prediction.primaryText ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(prediction.secondaryText ?? ''),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                              onTap: () => _selectPlace(prediction),
                            ),
                          );
                        },
                      ),

                    if (_isLoadingDetails)
                      Container(
                        color: Colors.white.withOpacity(0.6),
                        child: const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      ),
                  ],
                ),
              ),

              // Selected Location Details Card (Summary box)
              if (_selectedPlace != null && !_isLoadingDetails)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 0,
                    color: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: BorderSide(color: Colors.blueGrey.shade100, width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Selected Destination',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _selectedPlace!.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Text(
                            'Address: ${_selectedPlace!.address}',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Latitude: ${_selectedPlace!.latitude.toStringAsFixed(6)}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                              ),
                              Text(
                                'Longitude: ${_selectedPlace!.longitude.toStringAsFixed(6)}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop(_selectedPlace);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('Confirm Destination', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
