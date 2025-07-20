import 'package:finaltouch/homepage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a location first")),
      );
      return;
    }

    context.read<LocationBloc>().add(
      SaveLocationEvent(latLng: _selectedLocation, address: address),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LocationBloc, LocationState>(
      listener: (context, state) {
        if (state is LocationSaving) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Saving location...")),
          );
        } else if (state is LocationSaved) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Homepage()),
          );
        } else if (state is LocationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${state.message}")),
          );
        }
      },
      child: Scaffold(
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
                  ),
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: false,
              ),
            ),

            // Close button
            Positioned(
              top: 40,
              left: 16,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            // Title
            Positioned(
              top: 48,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Select location",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ),

            // Search bar and predictions dropdown
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  // Search input
                  Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(12),
                    child: TextField(
                      controller: searchController,
                      onChanged: _searchPlaces,
                      decoration: InputDecoration(
                        hintText: "Search location",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Predictions dropdown
                  if (predictions.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: predictions.length,
                        itemBuilder: (context, index) {
                          final p = predictions[index];
                          return ListTile(
                            title: Text(p.description ?? ''),
                            onTap: () => _selectPrediction(p),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

            // Confirm Button
            Positioned(
              bottom: 40,
              left: 32,
              right: 32,
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _confirmLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E86DE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    "Confirm location",
                    style: TextStyle(fontSize: 16, color: Colors.white),
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
