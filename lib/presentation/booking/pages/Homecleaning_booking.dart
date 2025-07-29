import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

// Import ONLY from the data folder - not logic folder
import 'package:finaltouch/features/booking/data/booking_Repository.dart';
import 'package:finaltouch/features/booking/logic/booking_bloc.dart';
import 'package:finaltouch/features/booking/logic/booking_event.dart';
import 'package:finaltouch/features/booking/logic/booking_state.dart';
import 'schedulemodule.dart';
import '../widgets/AddOns.dart';
import '../widgets/BookbuildStep1.dart';
import '../widgets/BookbuildStep2.dart';

class HomecleaningBooking extends StatelessWidget {
  const HomecleaningBooking({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BookingBloc(
        bookingRepository: BookingRepository(
          auth: FirebaseAuth.instance,
          firestore: FirebaseFirestore.instance,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: Colors.white,
          title: Text(
            "Book a cleaning",
            style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
          ),
        ),
        body: BlocListener<BookingBloc, BookingState>(
          listener: (context, state) {
            if (state is LocationFound) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider.value(
                    value: context.read<BookingBloc>(),
                    child: Schedulemodule(locationId: state.locationId),
                  ),
                ),
              );
            } else if (state is LocationNotFound) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is BookingError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const WidgetStep(),
                  const SizedBox(height: 20),
                  const Bookbuildstep2(),
                  const Addons(),
                  const SizedBox(height: 15),

                  BlocBuilder<BookingBloc, BookingState>(
                    builder: (context, state) {
                      final isLoading = state is LocationLoading;

                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () {
                            context.read<BookingBloc>().add(GetUserLocation());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1CABE3),
                            disabledBackgroundColor: Colors.grey.shade300,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
                                "Getting location...",
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          )
                              : Text(
                            "Continue",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  BlocBuilder<BookingBloc, BookingState>(
                    builder: (context, state) {
                      if (state is BookingDataUpdated && state.bookingData.isNotEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Complete Booking Data:",
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                state.bookingData.toString(),
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
          ),
        ),
      ),
    );
  }
}