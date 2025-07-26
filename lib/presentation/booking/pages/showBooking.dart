import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'features/booking/data/booking_Repository.dart'; // Adjust this import to your file structure

class ShowBookingScreen extends StatelessWidget {
  final BookingRepository bookingRepository;

  const ShowBookingScreen({super.key, required this.bookingRepository});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: null,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text("Error loading bookings"));
        }

        final bookings = snapshot.data?.docs ?? [];

        if (bookings.isEmpty) {
          return const Center(child: Text("No upcoming bookings"));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final data = bookings[index].data();
            final timestamp = data['scheduleDate'] as Timestamp?;
            final date = timestamp?.toDate();
            final time = data['selectedTime'] ?? '--';
            final address = data['address'] ?? 'No address';

            final formattedDate = date != null
                ? "${_weekdayName(date.weekday)}, ${date.day} ${_monthName(date.month)}"
                : "No date";

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 110, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(formattedDate,
                      style: GoogleFonts.manrope(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text("Details: $address",
                      style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: Color(0xff61758A))),
                  const SizedBox(height: 5),
                  Text("Time: $time",
                      style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: Color(0xff61758A))),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
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
