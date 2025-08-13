// lib/presentation/booking/pages/Homecleaning_booking.dart - FIXED PROGRESS LOGIC
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:finaltouch/features/booking/data/booking_Repository.dart';
import 'package:finaltouch/features/booking/logic/booking_bloc.dart';
import 'package:finaltouch/features/booking/logic/booking_event.dart';
import 'package:finaltouch/features/booking/logic/booking_state.dart';
import 'schedulemodule.dart';
import '../widgets/AddOns.dart';
import '../widgets/BookbuildStep1.dart';
import '../widgets/BookbuildStep2.dart';
import '../widgets/dynamic_pricing_widget.dart';

class HomecleaningBooking extends StatefulWidget {
  const HomecleaningBooking({super.key});

  @override
  State<HomecleaningBooking> createState() => _HomecleaningBookingState();
}

class _HomecleaningBookingState extends State<HomecleaningBooking> {
  late BookingBloc _bookingBloc;

  @override
  void initState() {
    super.initState();
    _bookingBloc = BookingBloc(
      bookingRepository: BookingRepository(
        auth: FirebaseAuth.instance,
        firestore: FirebaseFirestore.instance,
      ),
    );
  }

  @override
  void dispose() {
    _bookingBloc.close();
    super.dispose();
  }

  void _proceedToSchedule() {
    // Validate that required data is present
    final currentData = _bookingBloc.currentBookingData;

    if (currentData['propertyType'] == null || currentData['propertyType'].toString().isEmpty) {
      _showValidationError("Please select a property type");
      return;
    }

    if (currentData['cleaningType'] == null || currentData['cleaningType'].toString().isEmpty) {
      _showValidationError("Please select a cleaning type");
      return;
    }

    // Get location and proceed
    _bookingBloc.add(GetUserLocation());
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bookingBloc,
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
          elevation: 0,
        ),
        body: BlocListener<BookingBloc, BookingState>(
          bloc: _bookingBloc,
          listener: (context, state) {
            if (state is LocationFound) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider.value(
                    value: _bookingBloc,
                    child: Schedulemodule(locationId: state.locationId),
                  ),
                ),
              );
            } else if (state is LocationNotFound) {
              _showValidationError(state.message);
            } else if (state is BookingError) {
              _showValidationError(state.error);
            }
          },
          child: Column(
            children: [
              // Sticky pricing header (compact version)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: const DynamicPricingWidget(
                  isCompact: true,
                  showDetails: false,
                ),
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Form sections
                        const WidgetStep(),
                        const SizedBox(height: 24),
                        const Bookbuildstep2(),
                        const SizedBox(height: 24),
                        const Addons(),
                        const SizedBox(height: 24),

                        // Detailed pricing breakdown
                        const DynamicPricingWidget(showDetails: true),
                        const SizedBox(height: 24),

                        // Continue button
                        BlocBuilder<BookingBloc, BookingState>(
                          bloc: _bookingBloc,
                          builder: (context, state) {
                            final isLoading = state is LocationLoading;
                            final data = _bookingBloc.currentBookingData;
                            final hasPropertyType = data['propertyType'] != null && data['propertyType'].toString().isNotEmpty;
                            final hasCleaningType = data['cleaningType'] != null && data['cleaningType'].toString().isNotEmpty;
                            final canProceed = hasPropertyType && hasCleaningType;

                            // Different button states based on form completion
                            String buttonText;
                            IconData? buttonIcon;
                            Color buttonColor;

                            if (isLoading) {
                              buttonText = "Getting location...";
                              buttonIcon = null;
                              buttonColor = const Color(0xFF1CABE3);
                            } else if (canProceed) {
                              buttonText = "Continue to Schedule";
                              buttonIcon = Icons.arrow_forward;
                              buttonColor = const Color(0xFF1CABE3);
                            } else {
                              buttonText = "Complete form to continue";
                              buttonIcon = null;
                              buttonColor = Colors.grey.shade400;
                            }

                            return Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: canProceed ? [
                                  BoxShadow(
                                    color: const Color(0xFF1CABE3).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ] : null,
                              ),
                              child: ElevatedButton(
                                onPressed: (isLoading || !canProceed) ? null : _proceedToSchedule,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: buttonColor,
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: canProceed ? 2 : 0,
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
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                                    : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      buttonText,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: canProceed ? Colors.white : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


}