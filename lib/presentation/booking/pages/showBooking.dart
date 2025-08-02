import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../features/booking/showBooking/data/booking_display_repository.dart';
import '../../../features/booking/showBooking/logic/booking_display_Bloc.dart';
import '../../../features/booking/showBooking/logic/booking_display_event.dart';
import '../../../features/booking/showBooking/logic/booking_display_state.dart';
import 'showBooking.dart'; // Import your full booking screen

class UpcomingBookingsWidget extends StatelessWidget {
  const UpcomingBookingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BookingDisplayBloc(
        bookingDisplayRepository: BookingDisplayRepository(
          auth: FirebaseAuth.instance,
          firestore: FirebaseFirestore.instance,
        ),
      )..add(LoadBookings()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with "View All" button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Upcoming Bookings",
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to full ShowBookingScreen
                    /*Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ShowBookingScreen(),
                      ),
                    );*/
                  },
                  child: Text(
                    "View All",
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: const Color(0xFF1CABE3),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Bookings List - Show only upcoming ones, max 3
          BlocBuilder<BookingDisplayBloc, BookingDisplayState>(
            builder: (context, state) {
              if (state is BookingDisplayLoading) {
                return const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1CABE3),
                    ),
                  ),
                );
              }

              if (state is BookingDisplayError) {
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade600, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          "Error loading bookings",
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            context.read<BookingDisplayBloc>().add(RefreshBookings());
                          },
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is BookingDisplayLoaded) {
                final upcomingBookings = _getUpcomingBookings(state.bookings);

                if (upcomingBookings.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "No upcoming bookings",
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Book a cleaning service to see it here",
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

                // Show max 3 upcoming bookings
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: upcomingBookings.length > 3 ? 3 : upcomingBookings.length,
                  itemBuilder: (context, index) {
                    final booking = upcomingBookings[index];
                    return _buildCompactBookingCard(booking);
                  },
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getUpcomingBookings(List<Map<String, dynamic>> allBookings) {
    final now = DateTime.now();

    final upcoming = allBookings.where((booking) {
      final dateString = booking['selectedDate'] as String?;
      if (dateString == null) return false;

      try {
        final bookingDate = DateTime.parse(dateString);
        return bookingDate.isAfter(now.subtract(const Duration(days: 1)));
      } catch (e) {
        return false;
      }
    }).toList();

    // Sort by date (earliest first)
    upcoming.sort((a, b) {
      try {
        final dateA = DateTime.parse(a['selectedDate']);
        final dateB = DateTime.parse(b['selectedDate']);
        return dateA.compareTo(dateB);
      } catch (e) {
        return 0;
      }
    });

    return upcoming;
  }

  Widget _buildCompactBookingCard(Map<String, dynamic> booking) {
    final dateString = booking['selectedDate'] as String?;
    final selectedTime = booking['selectedTime'] as String? ?? 'Time not set';
    final cleaningType = booking['cleaningType'] as String? ?? 'Standard Cleaning';
    final status = booking['status'] as String? ?? 'pending';

    DateTime? bookingDate;
    try {
      if (dateString != null) {
        bookingDate = DateTime.parse(dateString);
      }
    } catch (e) {
      bookingDate = null;
    }

    final formattedDate = bookingDate != null
        ? "${_weekdayName(bookingDate.weekday)}, ${bookingDate.day} ${_monthName(bookingDate.month)}"
        : "Date not set";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Date circle
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF1CABE3).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  bookingDate?.day.toString() ?? "--",
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1CABE3),
                  ),
                ),
                Text(
                  bookingDate != null ? _monthName(bookingDate.month) : "--",
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    color: const Color(0xFF1CABE3),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Booking details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedDate,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  cleaningType,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: const Color(0xff61758A),
                  ),
                ),
                Text(
                  selectedTime,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: const Color(0xff61758A),
                  ),
                ),
              ],
            ),
          ),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status.toUpperCase(),
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
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