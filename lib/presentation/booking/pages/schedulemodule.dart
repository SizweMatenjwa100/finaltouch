// lib/presentation/booking/pages/schedulemodule.dart - UPDATED WITH PAYMENT
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:finaltouch/features/booking/logic/booking_bloc.dart';
import 'package:finaltouch/features/booking/logic/booking_event.dart';
import 'package:finaltouch/features/booking/logic/booking_state.dart';
import 'package:finaltouch/features/payment/logic/payment_bloc.dart';
import 'package:finaltouch/features/payment/data/payment_repository.dart';
import '../../payments/pages/simple_payment_test.dart';
import '../widgets/dynamic_pricing_widget.dart';
import '../../../services/pricing_service.dart';

class Schedulemodule extends StatefulWidget {
  final String locationId;

  const Schedulemodule({super.key, required this.locationId});

  @override
  State<Schedulemodule> createState() => _SchedulemoduleState();
}

class _SchedulemoduleState extends State<Schedulemodule> {
  DateTime _selectedDate = DateTime.now();
  String _selectedTime = '';
  bool _sameCleaner = false;

  final List<String> _timeSlots = [
    '8:00 AM - 10:00 AM',
    '10:00 AM - 12:00 PM',
    '12:00 PM - 2:00 PM',
    '2:00 PM - 4:00 PM',
    '4:00 PM - 6:00 PM'
  ];

  void _updateBookingData() {
    if (_selectedTime.isNotEmpty) {
      print("📅 Updating schedule: $_selectedDate, $_selectedTime, same cleaner: $_sameCleaner");
      context.read<BookingBloc>().add(
        SetSchedule(
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          sameCleaner: _sameCleaner,
        ),
      );
    }
  }

  void _proceedToPayment() {
    if (_selectedTime.isEmpty) {
      _showError("Please select a time slot");
      return;
    }

    // Get current booking data from bloc
    final currentBookingData = context.read<BookingBloc>().currentBookingData;

    // Validate required fields
    if (currentBookingData['propertyType'] == null || currentBookingData['propertyType'].toString().isEmpty) {
      _showError("Property type is missing. Please go back and select it.");
      return;
    }

    if (currentBookingData['cleaningType'] == null || currentBookingData['cleaningType'].toString().isEmpty) {
      _showError("Cleaning type is missing. Please go back and select it.");
      return;
    }

    // Create complete booking data with location and schedule
    final completeBookingData = {
      ...currentBookingData,
      'locationId': widget.locationId,
      'selectedDate': _selectedDate.toIso8601String(),
      'selectedTime': _selectedTime,
      'sameCleaner': _sameCleaner,
    };

    // Add pricing information
    final priceBreakdown = PricingService.calculatePrice(completeBookingData);
    completeBookingData['totalPrice'] = priceBreakdown.total;
    completeBookingData['priceBreakdown'] = {
      'basePrice': priceBreakdown.basePrice,
      'roomsPrice': priceBreakdown.roomsPrice,
      'addOnsPrice': priceBreakdown.addOnsPrice,
      'sameCleanerFee': priceBreakdown.sameCleanerFee,
      'estimatedDuration': priceBreakdown.estimatedHours,
    };

    print("🗓️ Proceeding to payment for location: ${widget.locationId}");
    print("💰 Total price: ${PricingService.formatPrice(priceBreakdown.total)}");

    // Save booking first with status 'pending_payment'
    _saveBookingAndProceedToPayment(completeBookingData);
  }

  void _saveBookingAndProceedToPayment(Map<String, dynamic> bookingData) async {
    try {
      // Don't save booking yet - just proceed to payment with complete data
      final completeBookingData = Map<String, dynamic>.from(bookingData);

      // Ensure all schedule data is included
      completeBookingData.addAll({
        'selectedDate': _selectedDate.toIso8601String(),
        'selectedTime': _selectedTime,
        'sameCleaner': _sameCleaner,
        'locationId': widget.locationId,
      });

      print("🚀 Complete booking data before payment: $completeBookingData");

      // Navigate directly to payment with complete data
      _navigateToPayment(completeBookingData);

    } catch (e) {
      _showError("Error preparing payment: $e");
    }
  }

  void _showError(String message) {
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

  bool _isDateAvailable(DateTime date) {
    if (date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return false;
    }
    if (date.isAfter(DateTime.now().add(const Duration(days: 90)))) {
      return false;
    }
    return true;
  }

  List<String> _getAvailableTimeSlots() {
    if (isSameDay(_selectedDate, DateTime.now())) {
      final now = DateTime.now();
      return _timeSlots.where((timeSlot) {
        final hour = int.parse(timeSlot.split(':')[0]);
        final isAM = timeSlot.contains('AM');
        final hourIn24 = isAM ? (hour == 12 ? 0 : hour) : (hour == 12 ? 12 : hour + 12);
        return hourIn24 > now.hour + 1;
      }).toList();
    }
    return _timeSlots;
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(days: 1));
  }

  @override
  Widget build(BuildContext context) {
    final availableTimeSlots = _getAvailableTimeSlots();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => PaymentBloc(
            paymentRepository: PaymentRepository(
              firestore: FirebaseFirestore.instance,
              auth: FirebaseAuth.instance,
            ),
          ),
        ),
      ],
      child: BlocListener<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state is BookingSuccess) {
            // Booking saved successfully, now proceed to payment
            final bookingData = context.read<BookingBloc>().currentBookingData;
            _navigateToPayment(bookingData);
          } else if (state is BookingError) {
            _showError("Booking failed: ${state.error}");
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(
              "Schedule & Confirm",
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
            leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back)
            ),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          body: Column(
            children: [
              // Sticky pricing header
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
                        // Booking summary
                        _buildBookingSummary(),
                        const SizedBox(height: 24),

                        // Date selection
                        Text(
                          "Select Date",
                          style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Choose when you'd like your cleaning service",
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Calendar
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TableCalendar(
                            focusedDay: _selectedDate,
                            firstDay: DateTime.now(),
                            lastDay: DateTime.now().add(const Duration(days: 90)),
                            selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
                            enabledDayPredicate: _isDateAvailable,
                            onDaySelected: (selected, focused) {
                              if (_isDateAvailable(selected)) {
                                setState(() {
                                  _selectedDate = selected;
                                  _selectedTime = '';
                                });
                                _updateBookingData();
                              }
                            },
                            calendarStyle: CalendarStyle(
                              selectedDecoration: const BoxDecoration(
                                color: Color(0xFF1CABE3),
                                shape: BoxShape.circle,
                              ),
                              todayDecoration: BoxDecoration(
                                color: const Color(0xFF1CABE3).withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              weekendDecoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              disabledDecoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              outsideDaysVisible: false,
                            ),
                            headerStyle: const HeaderStyle(
                              formatButtonVisible: false,
                              titleCentered: true,
                            ),
                          ),
                        ),

                        // Weekend notice
                        if (_selectedDate.weekday == DateTime.saturday || _selectedDate.weekday == DateTime.sunday) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.weekend, color: Colors.orange.shade700, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Weekend service includes a 20% premium charge",
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Time selection
                        Text(
                          "Select Time",
                          style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (availableTimeSlots.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Text(
                              "No available time slots for selected date. Please choose another date.",
                              style: GoogleFonts.manrope(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        else
                          Column(
                            children: availableTimeSlots.map((timeSlot) {
                              final isSelected = _selectedTime == timeSlot;
                              final isPeak = timeSlot == '10:00 AM - 12:00 PM' ||
                                  timeSlot == '12:00 PM - 2:00 PM' ||
                                  timeSlot == '2:00 PM - 4:00 PM';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedTime = timeSlot;
                                    });
                                    _updateBookingData();
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF1CABE3).withOpacity(0.1)
                                          : Colors.white,
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF1CABE3)
                                            : Colors.grey.shade300,
                                        width: isSelected ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          color: isSelected
                                              ? const Color(0xFF1CABE3)
                                              : Colors.grey.shade600,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            timeSlot,
                                            style: GoogleFonts.manrope(
                                              fontSize: 16,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              color: isSelected ? const Color(0xFF1CABE3) : Colors.black,
                                            ),
                                          ),
                                        ),
                                        if (isPeak)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.shade100,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              "+10% Peak",
                                              style: GoogleFonts.manrope(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.orange.shade700,
                                              ),
                                            ),
                                          ),
                                        if (isSelected)
                                          Container(
                                            margin: const EdgeInsets.only(left: 8),
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF1CABE3),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                        const SizedBox(height: 24),

                        // Same cleaner option
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Request Same Cleaner",
                                      style: GoogleFonts.manrope(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Get the same cleaner for future bookings (+R50)",
                                      style: GoogleFonts.manrope(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                activeColor: const Color(0xFF1CABE3),
                                value: _sameCleaner,
                                onChanged: (value) {
                                  setState(() {
                                    _sameCleaner = value;
                                  });
                                  _updateBookingData();
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Final pricing
                        const DynamicPricingWidget(showDetails: true),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom confirm button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Terms
                    Text(
                      "By proceeding, you agree to our Terms of Service and Privacy Policy",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Proceed to payment button
                    BlocBuilder<BookingBloc, BookingState>(
                      builder: (context, state) {
                        final isLoading = state is BookingLoading;
                        final canSubmit = _selectedTime.isNotEmpty;

                        return SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: (isLoading || !canSubmit) ? null : _proceedToPayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canSubmit
                                  ? const Color(0xFF1CABE3)
                                  : Colors.grey.shade300,
                              disabledBackgroundColor: Colors.grey.shade300,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: canSubmit ? 4 : 0,
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
                                  "Preparing Payment...",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            )
                                : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.payment, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  canSubmit ? "Proceed to Payment" : "Please select time",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: canSubmit ? Colors.white : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingSummary() {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        final data = context.read<BookingBloc>().currentBookingData;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1CABE3).withOpacity(0.1),
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1CABE3).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.summarize, color: Color(0xFF1CABE3), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Booking Summary",
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1CABE3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (data['propertyType'] != null)
                _buildSummaryRow(
                  Icons.home,
                  "Property",
                  "${data['propertyType']} • ${data['bedrooms']} bed • ${data['bathrooms']} bath",
                ),

              if (data['cleaningType'] != null)
                _buildSummaryRow(
                  Icons.cleaning_services,
                  "Service",
                  data['cleaningType'],
                ),

              if (data['addOns'] != null)
                _buildSummaryRow(
                  Icons.add_circle_outline,
                  "Add-ons",
                  _getSelectedAddOnsText(data['addOns']),
                ),

              _buildSummaryRow(
                Icons.location_on,
                "Location",
                widget.locationId,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            "$label:",
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSelectedAddOnsText(Map<String, dynamic> addOns) {
    final selected = addOns.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();

    return selected.isEmpty ? "None selected" : selected.join(", ");
  }

  void _navigateToPayment(Map<String, dynamic> bookingData) {
    // Generate a proper booking ID
    final bookingId = 'booking_${DateTime.now().millisecondsSinceEpoch}';

    // Ensure all required data is present
    final completeBookingData = {
      ...bookingData,
      'locationId': widget.locationId,
      'selectedDate': _selectedDate.toIso8601String(),
      'selectedTime': _selectedTime,
      'sameCleaner': _sameCleaner,
    };

    print("🚀 Navigating to payment with data: $completeBookingData");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => PaymentBloc(
            paymentRepository: PaymentRepository(
              firestore: FirebaseFirestore.instance,
              auth: FirebaseAuth.instance,
            ),
          ),
          child: SimplePaymentTest(
            bookingId: bookingId,
            locationId: widget.locationId,
            bookingData: completeBookingData,
          ),
        ),
      ),
    );
  }
}