// lib/presentation/location/location_screen.dart - Updated with consistent design and navigation
import 'package:finaltouch/main_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';
import '../../features/location/logic/locationBloc.dart';
import '../../features/location/logic/locationEvent.dart';
import '../../features/location/logic/locationState.dart';

class SelectLocationScreen extends StatefulWidget {
  const SelectLocationScreen({super.key});

  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  final String apiKey = "AIzaSyArRvTzypDIaMSf0QV7osqbhCf7w_ylOM8";
  late GoogleMapController _mapController;
  late GooglePlace _googlePlace;

  List<AutocompletePrediction> predictions = [];
  final searchController = TextEditingController();
  LatLng _selectedLocation = const LatLng(-33.918861, 18.4233); // Default Cape Town
  String? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _googlePlace = GooglePlace(apiKey);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _searchPlaces(String input) async {
    if (input.isNotEmpty) {
      var result = await _googlePlace.autocomplete.get(input, components: [
        Component("country", "za")
      ]);
      if (result != null && result.predictions != null) {
        setState(() {
          predictions = result.predictions!;
        });
      }
    } else {
      setState(() {
        predictions = [];
      });
    }
  }

  void _selectPrediction(AutocompletePrediction prediction) async {
    final placeId = prediction.placeId;
    final details = await _googlePlace.details.get(placeId!);
    if (details != null && details.result != null) {
      final location = details.result!.geometry!.location!;
      final latLng = LatLng(location.lat!, location.lng!);

      setState(() {
        _selectedLocation = latLng;
        _selectedAddress = details.result!.formattedAddress ?? details.result!.name!;
        searchController.text = details.result!.name!;
        predictions.clear();
      });

      _mapController.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
    }
  }

  void _confirmLocation() {
    final address = _selectedAddress ?? searchController.text;
    if (address.isEmpty) {
      _showError("Please select a location first");
      return;
    }

    context.read<LocationBloc>().add(
      SaveLocationEvent(latLng: _selectedLocation, address: address),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessAndNavigate() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            const Expanded(child: Text("Location saved successfully!")),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );

    // Navigate to MainNavigation after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
              (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LocationBloc, LocationState>(
      listener: (context, state) {
        if (state is LocationSaving) {
          // Show loading state handled by button
        } else if (state is LocationSaved) {
          _showSuccessAndNavigate();
        } else if (state is LocationError) {
          _showError("Error: ${state.message}");
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Google Map
            Positioned.fill(
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _selectedLocation,
                  zoom: 14,
                ),
                onTap: (pos) {
                  setState(() {
                    _selectedLocation = pos;
                    _selectedAddress = null;
                  });
                },
                markers: {
                  Marker(
                    markerId: const MarkerId('selectedLocation'),
                    position: _selectedLocation,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                  ),
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: false, // We'll create our own
                zoomControlsEnabled: false,
                style: '''
                [
                  {
                    "featureType": "poi",
                    "elementType": "labels",
                    "stylers": [{"visibility": "off"}]
                  }
                ]
                ''',
              ),
            ),

            // Top content overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      Colors.white.withOpacity(0.9),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.7, 1.0],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with back button and title
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.black),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Select Location",
                                    style: GoogleFonts.manrope(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    "Choose your service location",
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Search bar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: searchController,
                            onChanged: _searchPlaces,
                            style: GoogleFonts.manrope(fontSize: 16),
                            decoration: InputDecoration(
                              hintText: "Search for a location...",
                              hintStyle: GoogleFonts.manrope(
                                color: Colors.grey.shade500,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Color(0xFF1CABE3),
                              ),
                              suffixIcon: searchController.text.isNotEmpty
                                  ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: Colors.grey.shade600,
                                ),
                                onPressed: () {
                                  searchController.clear();
                                  setState(() {
                                    predictions.clear();
                                  });
                                },
                              )
                                  : null,
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF1CABE3),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Predictions dropdown
                        if (predictions.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: predictions.length,
                              itemBuilder: (context, index) {
                                final prediction = predictions[index];
                                return ListTile(
                                  leading: const Icon(
                                    Icons.location_on,
                                    color: Color(0xFF1CABE3),
                                  ),
                                  title: Text(
                                    prediction.structuredFormatting?.mainText ?? prediction.description ?? '',
                                    style: GoogleFonts.manrope(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    prediction.structuredFormatting?.secondaryText ?? '',
                                    style: GoogleFonts.manrope(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  onTap: () => _selectPrediction(prediction),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // My location button
            Positioned(
              bottom: 120,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {
                    // Get user's current location
                    // This would require location permissions
                  },
                  icon: const Icon(
                    Icons.my_location,
                    color: Color(0xFF1CABE3),
                  ),
                ),
              ),
            ),

            // Bottom confirm section
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Drag indicator
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Selected location info
                        if (_selectedAddress != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1CABE3).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF1CABE3).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Color(0xFF1CABE3),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Selected Location",
                                        style: GoogleFonts.manrope(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1CABE3),
                                        ),
                                      ),
                                      Text(
                                        _selectedAddress!,
                                        style: GoogleFonts.manrope(
                                          fontSize: 13,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Confirm button
                        BlocBuilder<LocationBloc, LocationState>(
                          builder: (context, state) {
                            final isLoading = state is LocationSaving;
                            final hasLocation = _selectedAddress != null || searchController.text.isNotEmpty;

                            return SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: (isLoading || !hasLocation) ? null : _confirmLocation,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: hasLocation && !isLoading
                                      ? const Color(0xFF1CABE3)
                                      : Colors.grey.shade300,
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: hasLocation && !isLoading ? 4 : 0,
                                ),
                                child: isLoading
                                    ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      "Saving location...",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                                    : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      hasLocation ? Icons.check : Icons.location_on,
                                      color: hasLocation && !isLoading
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      hasLocation ? "Confirm Location" : "Select a location",
                                      style: GoogleFonts.manrope(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: hasLocation && !isLoading
                                            ? Colors.white
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 8),

                        // Helper text
                        Text(
                          "Tap on the map or search to select your location",
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}