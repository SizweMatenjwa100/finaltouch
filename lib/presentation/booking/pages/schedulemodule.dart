import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:finaltouch/features/booking/logic/booking_bloc.dart';
import 'package:finaltouch/features/booking/logic/booking_event.dart';
import 'package:finaltouch/features/booking/logic/booking_state.dart';

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
      context.read<BookingBloc>().add(
        SetSchedule(
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          sameCleaner: _sameCleaner,
        ),
      );
    }
  }

  void _submitBooking() {
    if (_selectedTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a time slot"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get current booking data and add locationId
    final currentBookingData = context.read<BookingBloc>().currentBookingData;
    final completeBookingData = {
      ...currentBookingData,
      'locationId': widget.locationId, // Pass the locationId
      'selectedDate': _selectedDate.toIso8601String(),
      'selectedTime': _selectedTime,
      'sameCleaner': _sameCleaner,
    };

    print("🗓️ Submitting booking for location: ${widget.locationId}");
    context.read<BookingBloc>().add(SubmitBooking(completeBookingData));
  }

  bool _isDateAvailable(DateTime date) {
    // Don't allow past dates
    if (date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return false;
    }
    // Don't allow dates more than 3 months in future
    if (date.isAfter(DateTime.now().add(const Duration(days: 90)))) {
      return false;
    }
    return true;
  }

  List<String> _getAvailableTimeSlots() {
    // If selected date is today, filter out past time slots
    if (isSameDay(_selectedDate, DateTime.now())) {
      final now = DateTime.now();
      return _timeSlots.where((timeSlot) {
        final hour = int.parse(timeSlot.split(':')[0]);
        final isAM = timeSlot.contains('AM');
        final hourIn24 = isAM ? (hour == 12 ? 0 : hour) : (hour == 12 ? 12 : hour + 12);
        return hourIn24 > now.hour + 1; // Allow at least 1 hour notice
      }).toList();
    }
    return _timeSlots;
  }

  @override
  void initState() {
    super.initState();
    // Set minimum date to tomorrow
    _selectedDate = DateTime.now().add(const Duration(days: 1));
  }

  @override
  Widget build(BuildContext context) {
    final availableTimeSlots = _getAvailableTimeSlots();

    return BlocListener<BookingBloc, BookingState>(
      listener: (context, state) {
        if (state is BookingSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          // Navigate back to home or confirmation screen
          Navigator.popUntil(context, (route) => route.isFirst);
        } else if (state is BookingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Booking failed: ${state.error}"),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            "Schedule",
            style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back)
          ),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location indicator
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "Booking for location: ${widget.locationId}",
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  "Pick a date and time",
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Select when you'd like your cleaning service",
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 20),

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
                          // Reset time selection when date changes
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

                const SizedBox(height: 24),

                // Time slot selection
                Text(
                  "Available Time Slots",
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

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
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      hintText: "Select Time Slot",
                      hintStyle: GoogleFonts.manrope(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _selectedTime.isEmpty ? Colors.red.shade300 : Colors.grey.shade300,
                          width: 1.2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _selectedTime.isEmpty ? Colors.red.shade300 : Colors.grey.shade300,
                          width: 1.2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF1CABE3),
                          width: 2,
                        ),
                      ),
                    ),
                    value: _selectedTime.isEmpty ? null : _selectedTime,
                    items: availableTimeSlots.map((time) => DropdownMenuItem(
                      value: time,
                      child: Text(
                        time,
                        style: GoogleFonts.manrope(),
                      ),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTime = value!;
                      });
                      _updateBookingData();
                    },
                  ),

                if (_selectedTime.isEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    "Please select a time slot",
                    style: GoogleFonts.manrope(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ],

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
                              "Get the same cleaner for future bookings (subject to availability)",
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

                // Summary & Price
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1CABE3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF1CABE3).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Summary & Price Estimate",
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1CABE3),
                        ),
                      ),

                      const SizedBox(height: 16),

                      BlocBuilder<BookingBloc, BookingState>(
                        builder: (context, state) {
                          final bookingData = context.read<BookingBloc>().currentBookingData;

                          return Column(
                            children: [
                              if (bookingData.isNotEmpty) ...[
                                _buildSummaryRow("Property Type", bookingData['propertyType'] ?? 'Not selected'),
                                _buildSummaryRow("Bedrooms", "${bookingData['bedrooms'] ?? 'Not selected'}"),
                                _buildSummaryRow("Bathrooms", "${bookingData['bathrooms'] ?? 'Not selected'}"),
                                _buildSummaryRow("Cleaning Type", bookingData['cleaningType'] ?? 'Not selected'),
                                if (_selectedTime.isNotEmpty)
                                  _buildSummaryRow("Date & Time", "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} at $_selectedTime"),
                                if (bookingData.containsKey('addOns')) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    "Add-ons:",
                                    style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  ...Map<String, bool>.from(bookingData['addOns'])
                                      .entries
                                      .where((entry) => entry.value)
                                      .map((entry) => Padding(
                                    padding: const EdgeInsets.only(left: 16, top: 2),
                                    child: Text("• ${entry.key}", style: GoogleFonts.manrope(fontSize: 12)),
                                  )),
                                ],
                              ],

                              const Divider(height: 24, thickness: 1),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Estimated Total",
                                    style: GoogleFonts.manrope(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "R450",
                                    style: GoogleFonts.manrope(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1CABE3),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              Text(
                                "Final price may vary based on property condition",
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Submit booking button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: BlocBuilder<BookingBloc, BookingState>(
                    builder: (context, state) {
                      final isLoading = state is BookingLoading;

                      return ElevatedButton(
                        onPressed: (isLoading || _selectedTime.isEmpty) ? null : _submitBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1CABE3),
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: _selectedTime.isNotEmpty ? 2 : 0,
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
                              "Submitting...",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                            : Text(
                          "Confirm Booking",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _selectedTime.isNotEmpty ? Colors.white : Colors.grey.shade600,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Terms and conditions
                Center(
                  child: Text(
                    "By confirming, you agree to our Terms of Service and Privacy Policy",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}