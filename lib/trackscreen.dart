import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'features/booking/showBooking/data/booking_display_repository.dart';
import 'features/booking/showBooking/logic/booking_display_Bloc.dart';
import 'features/booking/showBooking/logic/booking_display_event.dart';
import 'features/booking/showBooking/logic/booking_display_state.dart';

class BookingTrackingScreen extends StatelessWidget {
  final String? bookingId; // Optional - if provided, shows specific booking

  const BookingTrackingScreen({super.key, this.bookingId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BookingDisplayBloc(
        bookingDisplayRepository: BookingDisplayRepository(
          auth: FirebaseAuth.instance,
          firestore: FirebaseFirestore.instance,
        ),
      )..add(LoadBookings()),
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text(
            "Track Booking",
            style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () {
                context.read<BookingDisplayBloc>().add(RefreshBookings());
              },
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: BlocBuilder<BookingDisplayBloc, BookingDisplayState>(
          builder: (context, state) {
            if (state is BookingDisplayLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF1CABE3),
                ),
              );
            }

            if (state is BookingDisplayError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Error loading bookings",
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          context.read<BookingDisplayBloc>().add(RefreshBookings());
                        },
                        child: const Text("Try Again"),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is BookingDisplayLoaded) {
              final activeBookings = _getActiveBookings(state.bookings);

              if (activeBookings.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No active bookings",
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Your confirmed and pending bookings will appear here",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                color: const Color(0xFF1CABE3),
                onRefresh: () async {
                  context.read<BookingDisplayBloc>().add(RefreshBookings());
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: activeBookings.length,
                  itemBuilder: (context, index) {
                    final booking = activeBookings[index];
                    return TrackingCard(booking: booking);
                  },
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getActiveBookings(List<Map<String, dynamic>> allBookings) {
    // Get bookings that are pending, confirmed, or in progress
    return allBookings.where((booking) {
      final status = booking['status'] as String? ?? 'pending';
      return ['pending', 'confirmed', 'in_progress', 'on_the_way'].contains(status.toLowerCase());
    }).toList();
  }
}

class TrackingCard extends StatelessWidget {
  final Map<String, dynamic> booking;

  const TrackingCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final dateString = booking['selectedDate'] as String?;
    final selectedTime = booking['selectedTime'] as String? ?? 'Time not set';
    final cleaningType = booking['cleaningType'] as String? ?? 'Standard Cleaning';
    final propertyType = booking['propertyType'] as String? ?? 'Property';
    final status = booking['status'] as String? ?? 'pending';
    final bookingId = booking['bookingId'] as String? ?? '';

    DateTime? bookingDate;
    try {
      if (dateString != null) {
        bookingDate = DateTime.parse(dateString);
      }
    } catch (e) {
      bookingDate = null;
    }

    final formattedDate = bookingDate != null
        ? "${_weekdayName(bookingDate.weekday)}, ${bookingDate.day} ${_monthName(bookingDate.month)} ${bookingDate.year}"
        : "Date not set";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cleaningType,
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$propertyType • $formattedDate",
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        selectedTime,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusDisplayText(status),
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Progress Steps
            _buildProgressSteps(status),

            const SizedBox(height: 20),

            // Booking ID
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.confirmation_number_outlined,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Booking ID: ${bookingId.substring(0, 8).toUpperCase()}",
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      //fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),

            // Action buttons based on status
            if (status.toLowerCase() == 'confirmed') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Call cleaner functionality
                      },
                      icon: const Icon(Icons.phone, size: 18),
                      label: Text(
                        "Call Cleaner",
                        style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1CABE3),
                        side: const BorderSide(color: Color(0xFF1CABE3)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Track on map functionality
                      },
                      icon: const Icon(Icons.location_on, size: 18),
                      label: Text(
                        "Track on Map",
                        style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1CABE3),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSteps(String currentStatus) {
    final steps = [
      {'status': 'pending', 'title': 'Booking Confirmed', 'subtitle': 'Your booking has been confirmed'},
      {'status': 'confirmed', 'title': 'Cleaner Assigned', 'subtitle': 'A cleaner has been assigned to your booking'},
      {'status': 'on_the_way', 'title': 'On The Way', 'subtitle': 'Cleaner is heading to your location'},
      {'status': 'in_progress', 'title': 'Cleaning Started', 'subtitle': 'Cleaning service is in progress'},
      {'status': 'completed', 'title': 'Completed', 'subtitle': 'Service completed successfully'},
    ];

    final currentIndex = steps.indexWhere((step) => step['status'] == currentStatus.toLowerCase());

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isCompleted = index <= currentIndex;
        final isCurrent = index == currentIndex;

        return Row(
          children: [
            // Step indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? const Color(0xFF1CABE3)
                    : Colors.grey.shade300,
                border: isCurrent
                    ? Border.all(color: const Color(0xFF1CABE3), width: 2)
                    : null,
              ),
              child: isCompleted
                  ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              )
                  : null,
            ),

            const SizedBox(width: 16),

            // Step content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step['title']!,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isCompleted ? Colors.black : Colors.grey.shade500,
                    ),
                  ),
                  Text(
                    step['subtitle']!,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: isCompleted ? Colors.grey.shade600 : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }).expand((widget) => [
        widget,
        if (steps.last != steps[steps.indexOf(steps.firstWhere((s) => s == widget))])
          Container(
            margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
            width: 2,
            height: 20,
            color: Colors.grey.shade300,
          ),
      ]).toList(),
    );
  }

  String _getStatusDisplayText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'CONFIRMED';
      case 'confirmed':
        return 'ASSIGNED';
      case 'on_the_way':
        return 'ON THE WAY';
      case 'in_progress':
        return 'IN PROGRESS';
      case 'completed':
        return 'COMPLETED';
      default:
        return status.toUpperCase();
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'on_the_way':
        return Colors.purple;
      case 'in_progress':
        return Colors.green;
      case 'completed':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _weekdayName(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[weekday - 1];
  }

  String _monthName(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return names[month - 1];
  }
}