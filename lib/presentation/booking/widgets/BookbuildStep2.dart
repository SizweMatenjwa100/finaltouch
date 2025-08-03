// lib/presentation/booking/widgets/BookbuildStep2.dart - FIXED VERSION
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
      'subtitle': 'Premium service: Includes deep cleaning plus specialized care.',
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
    print("🧹 Updating cleaning type: $cleaningType");
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
          Row(
            children: [
              Text(
                "Cleaning Type",
                style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text(
                "*",
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_selected.isEmpty)
            Text(
              "Please select a cleaning type",
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: Colors.red.shade600,
              ),
            ),
          const SizedBox(height: 20),

          // Options list
          ..._options.map((option) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              elevation: _selected == option['title'] ? 2 : 0,
              borderRadius: BorderRadius.circular(12),
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
                    color: _selected == option['title'] ? const Color(0xFF1CABE3) : Colors.black,
                  ),
                ),
                subtitle: Text(
                  option['subtitle']!,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _selected == option['title']
                        ? const Color(0xFF1CABE3)
                        : (_selected.isEmpty ? Colors.red.shade300 : Colors.grey.shade300),
                    width: _selected == option['title'] ? 2 : 1.2,
                  ),
                ),
                controlAffinity: ListTileControlAffinity.trailing,
                tileColor: _selected == option['title']
                    ? const Color(0xFF1CABE3).withOpacity(0.1)
                    : Colors.white,
                activeColor: const Color(0xFF1CABE3),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          )),

          const SizedBox(height: 20),

          // Selection confirmation
          BlocBuilder<BookingBloc, BookingState>(
            builder: (context, state) {
              final data = context.read<BookingBloc>().currentBookingData;
              if (data.containsKey('cleaningType') && data['cleaningType'].toString().isNotEmpty) {
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
                          "Selected: ${data['cleaningType']}",
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
    );
  }
}