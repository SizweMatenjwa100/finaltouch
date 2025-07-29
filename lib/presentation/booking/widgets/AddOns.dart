import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../features/booking/logic/booking_bloc.dart';
import '../../../features/booking/logic/booking_event.dart';
import '../../../features/booking/logic/booking_state.dart';

class Addons extends StatefulWidget {
  const Addons({super.key});

  @override
  State<Addons> createState() => _AddonsState();
}

class _AddonsState extends State<Addons> {
  Map<String, bool> addOns = {
    'Inside Oven': false,
    'Fridge': false,
    'Windows': false,
    'Pet Hair Removal': false,
  };

  void _updateBookingData() {
    context.read<BookingBloc>().add(
      SetAddOns(addOns: Map.from(addOns)),
    );
  }

  @override
  void initState() {
    super.initState();
    // Initialize with empty add-ons
    _updateBookingData();
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Add-ons",
            style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Add-ons list
          ...addOns.keys.map((title) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: CheckboxListTile(
                title: Text(
                  title,
                  style: GoogleFonts.manrope(fontSize: 16),
                ),
                value: addOns[title],
                onChanged: (bool? newValue) {
                  setState(() {
                    addOns[title] = newValue!;
                  });
                  _updateBookingData();
                },
                controlAffinity: ListTileControlAffinity.trailing,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                dense: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: Colors.white,
                checkColor: Colors.white,
                activeColor: const Color(0xFF1CABE3),
              ),
            );
          }).toList(),

          const SizedBox(height: 16),

          // Debug info (optional - shows selected add-ons)
          BlocBuilder<BookingBloc, BookingState>(
            builder: (context, state) {
              if (state is BookingDataUpdated && state.bookingData.containsKey('addOns')) {
                final selectedAddOns = Map<String, bool>.from(state.bookingData['addOns']);
                final selectedItems = selectedAddOns.entries
                    .where((entry) => entry.value)
                    .map((entry) => entry.key)
                    .toList();

                if (selectedItems.isNotEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Selected Add-ons:",
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...selectedItems.map((item) => Text(
                          "• $item",
                          style: GoogleFonts.manrope(fontSize: 12),
                        )),
                      ],
                    ),
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}