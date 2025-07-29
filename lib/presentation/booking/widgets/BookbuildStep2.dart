import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../features/booking/logic/booking_bloc.dart';
import '../../../features/booking/logic/booking_event.dart';
import '../../../features/booking/logic/booking_state.dart';

class Bookbuildstep2 extends StatefulWidget {
  const Bookbuildstep2({super.key});

  @override
  State<Bookbuildstep2> createState() => _Bookbuildstep2State();
}

class _Bookbuildstep2State extends State<Bookbuildstep2> {
  String _selected = '';

  final List<Map<String, String>> _options = [
    {
      'title': 'Standard',
      'subtitle': 'Basic cleaning: Dusting, vacuuming, mopping.',
    },
    {
      'title': 'Deep Cleaning',
      'subtitle': 'Thorough cleaning: Includes standard plus detailed cleaning of all areas.',
    },
    {
      'title': 'Premium Cleaning',
      'subtitle': 'Thorough cleaning: Includes standard plus detailed cleaning of all areas.',
    },
    {
      'title': 'Move-In/Out',
      'subtitle': 'Cleaning for moving: Empty property cleaning, all surfaces',
    },
    {
      'title': 'Spring Clean',
      'subtitle': 'Seasonal cleaning: Deep clean, focusing on neglected areas.'
    }
  ];

  void _updateBookingData(String cleaningType) {
    context.read<BookingBloc>().add(
      SetCleaningType(cleaningType: cleaningType),
    );
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
            "Cleaning Type",
            style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Options list
          ..._options.map((option) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RadioListTile<String>(
              value: option['title']!,
              groupValue: _selected,
              onChanged: (value) {
                setState(() {
                  _selected = value!;
                });
                _updateBookingData(value!);
              },
              title: Text(
                option['title']!,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                option['subtitle']!,
                style: GoogleFonts.manrope(fontSize: 16),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1.2,
                ),
              ),
              controlAffinity: ListTileControlAffinity.trailing,
              tileColor: Colors.white,
              activeColor: const Color(0xFF1CABE3),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            ),
          )),

          const SizedBox(height: 20),

          // Debug info (optional - shows current booking data)
          BlocBuilder<BookingBloc, BookingState>(
            builder: (context, state) {
              if (state is BookingDataUpdated && state.bookingData.containsKey('cleaningType')) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Selected Cleaning Type:",
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${state.bookingData['cleaningType']}",
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
    );
  }
}