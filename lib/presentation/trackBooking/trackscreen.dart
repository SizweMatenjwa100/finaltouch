// lib/presentation/trackBooking/trackscreen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/booking/showBooking/data/booking_display_repository.dart';
import '../../features/booking/showBooking/logic/booking_display_Bloc.dart';
import '../../features/booking/showBooking/logic/booking_display_event.dart';
import '../../features/booking/showBooking/logic/booking_display_state.dart';

class EnhancedTrackingScreen extends StatefulWidget {
  const EnhancedTrackingScreen({super.key});

  @override
  State<EnhancedTrackingScreen> createState() => _EnhancedTrackingScreenState();
}

class _EnhancedTrackingScreenState extends State<EnhancedTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late BookingDisplayBloc _bookingBloc;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _bookingBloc = BookingDisplayBloc(
      bookingDisplayRepository: BookingDisplayRepository(
        auth: FirebaseAuth.instance,
        firestore: FirebaseFirestore.instance,
      ),
    );
    _bookingBloc.add(LoadBookings());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bookingBloc.close();
    super.dispose();
  }

  void _refreshBookings() {
    _bookingBloc.add(RefreshBookings());
  }

  List<Map<String, dynamic>> _categorizeBookings(
      List<Map<String, dynamic>> bookings, String category) {
    final now = DateTime.now();

    return bookings.where((booking) {
      final status = (booking['status'] ?? 'pending').toString().toLowerCase();
      final selectedDateString = booking['selectedDate'] as String?;

      DateTime? bookingDate;
      if (selectedDateString != null) {
        try {
          bookingDate = DateTime.parse(selectedDateString);
        } catch (e) {
          print("Error parsing date: $selectedDateString");
        }
      }

      booking['cleaner'] = _generateCleanerInfo();
      booking['estimatedDuration'] = _getEstimatedDuration(booking['cleaningType']);

      switch (category) {
        case 'active':
          return ['in_progress', 'on_way', 'started'].contains(status);
        case 'upcoming':
          if (['confirmed', 'pending', 'rescheduled', 'paid'].contains(status)) {
            return bookingDate != null &&
                bookingDate.isAfter(now.subtract(const Duration(hours: 2)));
          }
          return false;
        case 'history':
          return ['completed', 'cancelled'].contains(status) ||
              (bookingDate != null && bookingDate.isBefore(now.subtract(const Duration(hours: 2))));
        default:
          return false;
      }
    }).toList();
  }

  Map<String, dynamic> _generateCleanerInfo() {
    final cleaners = [
      {
        'name': 'Thabo Mthembu',
        'rating': 4.8,
        'phone': '+27 82 123 4567',
        'avatar': 'assets/images/profileavatar.png',
        'experience': '5 years',
      },
      {
        'name': 'Nomsa Dlamini',
        'rating': 4.9,
        'phone': '+27 83 987 6543',
        'avatar': 'assets/images/profileavatar.png',
        'experience': '3 years',
      },
      {
        'name': 'John Smith',
        'rating': 4.7,
        'phone': '+27 84 555 1234',
        'avatar': 'assets/images/profileavatar.png',
        'experience': '7 years',
      },
    ];
    return cleaners[DateTime.now().millisecond % cleaners.length];
  }

  int _getEstimatedDuration(String? cleaningType) {
    switch (cleaningType?.toLowerCase()) {
      case 'standard':
        return 120;
      case 'deep cleaning':
        return 240;
      case 'premium cleaning':
        return 300;
      case 'move-in/out':
        return 480;
      case 'spring clean':
        return 360;
      default:
        return 120;
    }
  }

  bool _canStartBooking(Map<String, dynamic> booking) {
    final selectedDateString = booking['selectedDate'] as String?;
    if (selectedDateString == null) return false;

    try {
      final bookingDate = DateTime.parse(selectedDateString);
      final today = DateTime.now();

      return bookingDate.year == today.year &&
          bookingDate.month == today.month &&
          bookingDate.day == today.day;
    } catch (e) {
      return false;
    }
  }

  String _getBookingDateString(Map<String, dynamic> booking) {
    final selectedDateString = booking['selectedDate'] as String?;
    if (selectedDateString == null) return "the scheduled date";

    try {
      final bookingDate = DateTime.parse(selectedDateString);
      return _formatDate(bookingDate);
    } catch (e) {
      return "the scheduled date";
    }
  }

  void _startBooking(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Start Cleaning Service",
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1CABE3).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Color(0xFF1CABE3),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Are you ready to start your ${booking['cleaningType']} service?",
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "This will mark your service as active and in progress.",
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Not Yet",
              style: GoogleFonts.manrope(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _updateBookingStatus(booking, 'in_progress');
            },
            icon: const Icon(Icons.play_arrow, size: 16),
            label: Text(
              "Start Service",
              style: GoogleFonts.manrope(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1CABE3),
            ),
          ),
        ],
      ),
    );
  }

  void _updateBookingStatus(Map<String, dynamic> booking, String newStatus) {
    setState(() {
      booking['status'] = newStatus;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              newStatus == 'in_progress' ? Icons.play_arrow : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              newStatus == 'in_progress'
                  ? "Service started successfully!"
                  : "Service completed successfully!",
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    _refreshBookings();
  }

  void _showCloseOrderDialog(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Complete Service",
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Is your ${booking['cleaningType']} service complete?",
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "This will mark the service as completed and move it to your history.",
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Not Yet",
              style: GoogleFonts.manrope(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _updateBookingStatus(booking, 'completed');
            },
            icon: const Icon(Icons.check_circle, size: 16),
            label: Text(
              "Complete Service",
              style: GoogleFonts.manrope(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bookingBloc,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            "Track Bookings",
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 20,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              onPressed: _refreshBookings,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: BlocBuilder<BookingDisplayBloc, BookingDisplayState>(
              builder: (context, state) {
                if (state is BookingDisplayLoaded) {
                  final activeBookings = _categorizeBookings(state.bookings, 'active');
                  final upcomingBookings = _categorizeBookings(state.bookings, 'upcoming');
                  final historyBookings = _categorizeBookings(state.bookings, 'history');

                  return TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF1CABE3),
                    unselectedLabelColor: Colors.grey.shade600,
                    indicatorColor: const Color(0xFF1CABE3),
                    labelStyle: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                    tabs: [
                      Tab(
                        text: "Active${activeBookings.isNotEmpty ? ' (${activeBookings.length})' : ''}",
                      ),
                      Tab(
                        text: "Upcoming${upcomingBookings.isNotEmpty ? ' (${upcomingBookings.length})' : ''}",
                      ),
                      Tab(
                        text: "History${historyBookings.isNotEmpty ? ' (${historyBookings.length})' : ''}",
                      ),
                    ],
                  );
                }
                return TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF1CABE3),
                  unselectedLabelColor: Colors.grey.shade600,
                  indicatorColor: const Color(0xFF1CABE3),
                  labelStyle: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: "Active"),
                    Tab(text: "Upcoming"),
                    Tab(text: "History"),
                  ],
                );
              },
            ),
          ),
        ),
        body: BlocBuilder<BookingDisplayBloc, BookingDisplayState>(
          builder: (context, state) {
            if (state is BookingDisplayLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF1CABE3)),
              );
            } else if (state is BookingDisplayError) {
              return _buildErrorState(state.error);
            } else if (state is BookingDisplayLoaded) {
              if (state.bookings.isEmpty) {
                return _buildEmptyState();
              }

              final activeBookings = _categorizeBookings(state.bookings, 'active');
              final upcomingBookings = _categorizeBookings(state.bookings, 'upcoming');
              final historyBookings = _categorizeBookings(state.bookings, 'history');

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildActiveBookingsTab(activeBookings),
                  _buildUpcomingBookingsTab(upcomingBookings),
                  _buildHistoryTab(historyBookings),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              "Error Loading Bookings",
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _refreshBookings,
              icon: const Icon(Icons.refresh),
              label: const Text("Try Again"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1CABE3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cleaning_services_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              "No bookings yet",
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Book your first cleaning service to see tracking information here",
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                color: Colors.grey.shade500,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1CABE3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Book Now",
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBookingsTab(List<Map<String, dynamic>> activeBookings) {
    if (activeBookings.isEmpty) {
      return _buildNoActiveBookings();
    }

    return RefreshIndicator(
      onRefresh: () async => _refreshBookings(),
      color: const Color(0xFF1CABE3),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: activeBookings.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildActiveBookingCard(activeBookings[index]),
          );
        },
      ),
    );
  }

  Widget _buildUpcomingBookingsTab(List<Map<String, dynamic>> upcomingBookings) {
    if (upcomingBookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.schedule, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                "No upcoming bookings",
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _refreshBookings(),
      color: const Color(0xFF1CABE3),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: upcomingBookings.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildUpcomingBookingCard(upcomingBookings[index]),
          );
        },
      ),
    );
  }

  Widget _buildHistoryTab(List<Map<String, dynamic>> historyBookings) {
    if (historyBookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                "No booking history",
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _refreshBookings(),
      color: const Color(0xFF1CABE3),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: historyBookings.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildHistoryBookingCard(historyBookings[index]),
          );
        },
      ),
    );
  }

  Widget _buildNoActiveBookings() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1CABE3).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cleaning_services,
                size: 48,
                color: Color(0xFF1CABE3),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "No active cleanings",
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Your active cleaning sessions will appear here",
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBookingCard(Map<String, dynamic> booking) {
    final cleaner = booking['cleaner'] as Map<String, dynamic>;
    final cleaningType = booking['cleaningType'] ?? 'Standard Cleaning';
    final selectedTime = booking['selectedTime'] ?? 'Time not set';
    final estimatedDuration = booking['estimatedDuration'] ?? 120;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1CABE3).withOpacity(0.1),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1CABE3).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1CABE3).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1CABE3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cleaning_services,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Cleaning in Progress",
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1CABE3),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Live",
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              cleaningType,
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Started at $selectedTime • Est. ${(estimatedDuration / 60).round()} hours",
              style: GoogleFonts.manrope(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Progress",
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: 0.6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1CABE3)),
                  minHeight: 6,
                ),
                const SizedBox(height: 4),
                Text(
                  "60% Complete",
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: AssetImage(cleaner['avatar']),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cleaner['name'],
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${cleaner['rating']} • ${cleaner['experience']}",
                            style: GoogleFonts.manrope(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _showCallCleanerDialog(cleaner);
                  },
                  icon: const Icon(Icons.phone),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF1CABE3),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showTrackingDetails(booking);
                    },
                    icon: const Icon(Icons.location_on, size: 18),
                    label: Text(
                      "Track Progress",
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1CABE3),
                      side: const BorderSide(color: Color(0xFF1CABE3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showCloseOrderDialog(booking);
                    },
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: Text(
                      "Close Order",
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      _showChatWithCleaner(cleaner);
                    },
                    icon: const Icon(Icons.chat, size: 16),
                    label: Text(
                      "Chat with Cleaner",
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1CABE3),
                    ),
                  ),
                ),
                Container(
                  height: 24,
                  width: 1,
                  color: Colors.grey.shade300,
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      _showCallCleanerDialog(cleaner);
                    },
                    icon: const Icon(Icons.phone, size: 16),
                    label: Text(
                      "Call Cleaner",
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1CABE3),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingBookingCard(Map<String, dynamic> booking) {
    final cleaningType = booking['cleaningType'] ?? 'Standard Cleaning';
    final selectedDate = booking['selectedDate'] as String?;
    final selectedTime = booking['selectedTime'] ?? 'Time not set';
    final propertyType = booking['propertyType'] ?? 'Property';
    final bedrooms = booking['bedrooms'] ?? 1;
    final bathrooms = booking['bathrooms'] ?? 1;
    final status = (booking['status'] ?? 'pending').toString().toLowerCase();

    DateTime? bookingDateTime;
    if (selectedDate != null) {
      try {
        bookingDateTime = DateTime.parse(selectedDate);
      } catch (e) {
        print("Error parsing date: $selectedDate");
      }
    }

    final isConfirmed = ['confirmed', 'paid'].contains(status);
    final statusColor = isConfirmed ? Colors.green : Colors.orange;
    final statusText = isConfirmed ? 'Confirmed' : 'Pending';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isConfirmed ? Icons.check_circle : Icons.schedule,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cleaningType,
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusColor.withOpacity(0.3)),
                            ),
                            child: Text(
                              statusText.toUpperCase(),
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'cancel':
                        _showCancelDialog(booking);
                        break;
                      case 'reschedule':
                        _showRescheduleDialog(booking);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'reschedule',
                      child: Row(
                        children: [
                          Icon(Icons.schedule, size: 16),
                          SizedBox(width: 8),
                          Text('Reschedule'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'cancel',
                      child: Row(
                        children: [
                          Icon(Icons.cancel, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Cancel', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1CABE3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF1CABE3),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    bookingDateTime != null
                        ? "${_formatDate(bookingDateTime)} at $selectedTime"
                        : "Date not set",
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1CABE3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "$propertyType • $bedrooms bed • $bathrooms bath",
              style: GoogleFonts.manrope(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            if (booking['addOns'] != null) ...[
              const SizedBox(height: 12),
              _buildAddOns(booking['addOns']),
            ],
            const SizedBox(height: 16),
            if (isConfirmed) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRescheduleDialog(booking),
                      icon: const Icon(Icons.schedule, size: 16),
                      label: Text(
                        "Reschedule",
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _canStartBooking(booking)
                          ? () => _startBooking(booking)
                          : null,
                      icon: Icon(
                        _canStartBooking(booking) ? Icons.play_arrow : Icons.schedule,
                        size: 16,
                      ),
                      label: Text(
                        _canStartBooking(booking) ? "Start Order" : "Not Today",
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _canStartBooking(booking)
                            ? const Color(0xFF1CABE3)
                            : Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (!_canStartBooking(booking)) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "You can start this order on ${_getBookingDateString(booking)}",
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showCancelDialog(booking),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.manrope(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _completePayment(booking),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Complete Payment",
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _buildHistoryBookingCard(Map<String, dynamic> booking) {
    final cleaningType = booking['cleaningType'] ?? 'Standard Cleaning';
    final selectedDate = booking['selectedDate'] as String?;
    final status = booking['status'] ?? 'completed';

    DateTime? bookingDateTime;
    if (selectedDate != null) {
      try {
        bookingDateTime = DateTime.parse(selectedDate);
      } catch (e) {
        print("Error parsing date: $selectedDate");
      }
    }

    final isCompleted = status.toLowerCase() == 'completed';
    final statusColor = isCompleted ? Colors.green : Colors.red;
    final statusText = isCompleted ? 'Completed' : 'Cancelled';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCompleted ? Icons.check_circle : Icons.cancel,
                  color: statusColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                if (isCompleted)
                  TextButton(
                    onPressed: () => _showRateServiceDialog(booking),
                    child: Text(
                      "Rate Service",
                      style: GoogleFonts.manrope(
                        color: const Color(0xFF1CABE3),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              cleaningType,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              bookingDateTime != null
                  ? _formatDate(bookingDateTime)
                  : "Date not available",
              style: GoogleFonts.manrope(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOns(Map<String, dynamic> addOns) {
    final selectedAddOns = addOns.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();

    if (selectedAddOns.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: selectedAddOns.map((addon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1CABE3).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF1CABE3).withOpacity(0.3),
          ),
        ),
        child: Text(
          addon,
          style: GoogleFonts.manrope(
            fontSize: 12,
            color: const Color(0xFF1CABE3),
            fontWeight: FontWeight.w500,
          ),
        ),
      )).toList(),
    );
  }

  String _formatDate(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return "${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}";
  }

  void _confirmBooking(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Confirm Booking",
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Confirm your booking for ${booking['cleaningType']}?",
          style: GoogleFonts.manrope(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.manrope(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Booking confirmed!")),
              );
              _refreshBookings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1CABE3),
            ),
            child: Text(
              "Confirm",
              style: GoogleFonts.manrope(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Cancel Booking",
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to cancel this booking? This action cannot be undone.",
          style: GoogleFonts.manrope(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Keep Booking",
              style: GoogleFonts.manrope(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Booking cancelled"),
                  backgroundColor: Colors.red,
                ),
              );
              _refreshBookings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              "Cancel Booking",
              style: GoogleFonts.manrope(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showRescheduleDialog(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Reschedule Booking",
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "To reschedule your booking, please contact our support team.",
              style: GoogleFonts.manrope(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1CABE3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF1CABE3),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Free rescheduling up to 24 hours before service",
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: const Color(0xFF1CABE3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Close",
              style: GoogleFonts.manrope(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Opening support chat...")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1CABE3),
            ),
            child: Text(
              "Contact Support",
              style: GoogleFonts.manrope(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showCallCleanerDialog(Map<String, dynamic> cleaner) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Call ${cleaner['name']}",
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: AssetImage(cleaner['avatar']),
            ),
            const SizedBox(height: 16),
            Text(
              cleaner['name'],
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star,
                  size: 16,
                  color: Colors.amber.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  "${cleaner['rating']} rating",
                  style: GoogleFonts.manrope(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "Call ${cleaner['phone']}?",
              style: GoogleFonts.manrope(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.manrope(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Calling ${cleaner['phone']}...")),
              );
            },
            icon: const Icon(Icons.phone, size: 18),
            label: Text(
              "Call",
              style: GoogleFonts.manrope(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1CABE3),
            ),
          ),
        ],
      ),
    );
  }

  void _showTrackingDetails(Map<String, dynamic> booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Cleaning Progress",
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                booking['cleaningType'] ?? 'Cleaning Service',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              _buildProgressSteps(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSteps() {
    final steps = [
      {'title': 'Cleaner on the way', 'completed': true, 'time': '9:00 AM'},
      {'title': 'Arrived at location', 'completed': true, 'time': '9:15 AM'},
      {'title': 'Cleaning in progress', 'completed': true, 'time': '9:30 AM'},
      {'title': 'Final inspection', 'completed': false, 'time': 'Est. 11:00 AM'},
      {'title': 'Cleaning completed', 'completed': false, 'time': 'Est. 11:30 AM'},
    ];

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: step['completed'] as bool
                        ? const Color(0xFF1CABE3)
                        : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: step['completed'] as bool
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: step['completed'] as bool
                        ? const Color(0xFF1CABE3)
                        : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step['title'] as String,
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: step['completed'] as bool
                            ? Colors.black
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step['time'] as String,
                      style: GoogleFonts.manrope(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  void _showChatWithCleaner(Map<String, dynamic> cleaner) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Chat with ${cleaner['name']}",
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Chat feature coming soon! For now, you can call your cleaner directly.",
          style: GoogleFonts.manrope(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Close",
              style: GoogleFonts.manrope(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showCallCleanerDialog(cleaner);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1CABE3),
            ),
            child: Text(
              "Call Instead",
              style: GoogleFonts.manrope(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showRateServiceDialog(Map<String, dynamic> booking) {
    int selectedRating = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            "Rate Your Service",
            style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "How was your ${booking['cleaningType']} service?",
                style: GoogleFonts.manrope(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  onPressed: () {
                    setState(() {
                      selectedRating = index + 1;
                    });
                  },
                  icon: Icon(
                    Icons.star,
                    color: index < selectedRating
                        ? Colors.amber.shade600
                        : Colors.grey.shade300,
                    size: 32,
                  ),
                )),
              ),
              const SizedBox(height: 16),
              if (selectedRating > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Thanks for rating: $selectedRating star${selectedRating > 1 ? 's' : ''}!",
                    style: GoogleFonts.manrope(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Later",
                style: GoogleFonts.manrope(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: selectedRating > 0 ? () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Thank you for your $selectedRating-star rating!"),
                    backgroundColor: Colors.green,
                  ),
                );
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1CABE3),
              ),
              child: Text(
                "Submit",
                style: GoogleFonts.manrope(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _completePayment(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Complete Payment",
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Your booking is pending payment completion.",
              style: GoogleFonts.manrope(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Please complete payment to confirm your booking.",
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Later",
              style: GoogleFonts.manrope(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Redirecting to payment...")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: Text(
              "Pay Now",
              style: GoogleFonts.manrope(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}