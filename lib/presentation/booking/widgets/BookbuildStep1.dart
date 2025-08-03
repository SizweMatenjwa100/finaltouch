// lib/presentation/booking/widgets/BookbuildStep1.dart - FIXED VERSION
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
    if (_selectedPropertyType != null && _selectedPropertyType!.isNotEmpty) {
      print("🏠 Updating property info: $_selectedPropertyType, $_bedrooms bed, $_bathrooms bath");
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

            // Dropdown with validation indicator
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedPropertyType,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    fillColor: const Color(0xFFF5F5F5),
                    filled: true,
                    hintText: "Select Property Type *",
                    hintStyle: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: _selectedPropertyType == null ? Colors.red.shade400 : Colors.black,
                      fontSize: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: _selectedPropertyType == null ? Colors.red.shade300 : Colors.grey.shade300,
                        width: 1.2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: _selectedPropertyType == null ? Colors.red.shade300 : Colors.grey.shade300,
                        width: 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: _selectedPropertyType == null ? Colors.red.shade300 : const Color(0xFF1CABE3),
                        width: 1.5,
                      ),
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
                if (_selectedPropertyType == null) ...[
                  const SizedBox(height: 4),
                  Text(
                    "Property type is required",
                    style: GoogleFonts.manrope(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 30),

            // Bedrooms counter
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
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
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color: _bedrooms > 1 ? const Color(0xFF1CABE3) : Colors.grey,
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1CABE3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        "$_bedrooms",
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1CABE3),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (_bedrooms < 10) {
                        setState(() {
                          _bedrooms++;
                        });
                        _updateBookingData();
                      }
                    },
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFF1CABE3),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // Bathrooms counter
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
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
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color: _bathrooms > 1 ? const Color(0xFF1CABE3) : Colors.grey,
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1CABE3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        "$_bathrooms",
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1CABE3),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (_bathrooms < 10) {
                        setState(() {
                          _bathrooms++;
                        });
                        _updateBookingData();
                      }
                    },
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFF1CABE3),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Current selection display
            BlocBuilder<BookingBloc, BookingState>(
              builder: (context, state) {
                final data = context.read<BookingBloc>().currentBookingData;
                if (data.isNotEmpty && data.containsKey('propertyType')) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Property: ${data['propertyType']} with ${data['bedrooms']} bedrooms and ${data['bathrooms']} bathrooms",
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Colors.green.shade700,
                            ),
                          ),
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