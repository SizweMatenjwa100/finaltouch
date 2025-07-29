import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../features/booking/logic/booking_bloc.dart';
import '../../../features/booking/logic/booking_event.dart';
import '../../../features/booking/logic/booking_state.dart';

class WidgetStep extends StatefulWidget {
  const WidgetStep({super.key});

  @override
  State<WidgetStep> createState() => _WidgetStepState();
}

class _WidgetStepState extends State<WidgetStep> {
  int _bedrooms = 1;
  int _bathrooms = 1;
  String? _selectedPropertyType;

  void _updateBookingData() {
    if (_selectedPropertyType != null) {
      context.read<BookingBloc>().add(
        SetPropertyInfo(
          propertyType: _selectedPropertyType!,
          bedrooms: _bedrooms,
          bathrooms: _bathrooms,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BookingBloc, BookingState>(
      listener: (context, state) {
        if (state is BookingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              "Property Info",
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Dropdown
            DropdownButtonFormField<String>(
              value: _selectedPropertyType,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                fillColor: const Color(0xFFF5F5F5),
                filled: true,
                hintText: "Select Property Type",
                hintStyle: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  fontSize: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                ),
              ),
              items: ['Apartment', 'House', 'Cottage'].map((e) {
                return DropdownMenuItem(
                    value: e,
                    child: Text(e, style: GoogleFonts.manrope())
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedPropertyType = val;
                });
                _updateBookingData();
              },
            ),

            const SizedBox(height: 30),

            // Bedrooms
            Row(
              children: [
                Text(
                  "Bedrooms",
                  style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    if (_bedrooms > 1) {
                      setState(() {
                        _bedrooms--;
                      });
                      _updateBookingData();
                    }
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  "$_bedrooms",
                  style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _bedrooms++;
                    });
                    _updateBookingData();
                  },
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Bathrooms
            Row(
              children: [
                Text(
                  "Bathrooms",
                  style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    if (_bathrooms > 1) {
                      setState(() {
                        _bathrooms--;
                      });
                      _updateBookingData();
                    }
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  "$_bathrooms",
                  style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _bathrooms++;
                    });
                    _updateBookingData();
                  },
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Debug info (optional - shows current booking data)
            BlocBuilder<BookingBloc, BookingState>(
              builder: (context, state) {
                if (state is BookingDataUpdated && state.bookingData.isNotEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Current Selection:",
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Property: ${state.bookingData['propertyType'] ?? 'Not selected'}",
                          style: GoogleFonts.manrope(fontSize: 12),
                        ),
                        Text(
                          "Bedrooms: ${state.bookingData['bedrooms'] ?? 'Not set'}",
                          style: GoogleFonts.manrope(fontSize: 12),
                        ),
                        Text(
                          "Bathrooms: ${state.bookingData['bathrooms'] ?? 'Not set'}",
                          style: GoogleFonts.manrope(fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}