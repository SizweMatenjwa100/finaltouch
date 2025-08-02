// lib/presentation/tracking/enhanced_tracking_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../features/booking/data/booking_Repository.dart';

class EnhancedTrackingScreen extends StatefulWidget {
  const EnhancedTrackingScreen({super.key});

  @override
  State<EnhancedTrackingScreen> createState() => _EnhancedTrackingScreenState();
}

class _EnhancedTrackingScreenState extends State<EnhancedTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late BookingRepository _bookingRepository;
  bool _isLoading = true;
  List<Map<String, dynamic>> _allBookings = [];
  List<Map<String, dynamic>> _activeBookings = [];
  List<Map<String, dynamic>> _upcomingBookings = [];
  List<Map<String, dynamic>> _completedBookings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _bookingRepository = BookingRepository(
      auth: FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
    );
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bookings = await _bookingRepository.getUserBookings();
      _categorizeBookings(bookings);
    } catch (e) {
      print("Error loading bookings: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading bookings: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _categorizeBookings(List<Map<String, dynamic>> bookings) {
    final now = DateTime.now();
    final active = <Map<String, dynamic>>[];
    final upcoming = <Map<String, dynamic>>[];
    final completed = <Map<String, dynamic>>[];

    for (final booking in bookings) {
      final status = booking['status'] ?? 'pending';
      final selectedDateString = booking['selectedDate'] as String?;

      // Add cleaner info and estimated duration
      booking['cleaner'] = _generateCleanerInfo();
      booking['estimatedDuration'] = _getEstimatedDuration(booking['cleaningType']);

      DateTime? bookingDate;
      if (selectedDateString != null) {
        try {
          bookingDate = DateTime.parse(selectedDateString);
        } catch (e) {
          print("Error parsing date: $selectedDateString");
        }
      }

      switch (status.toLowerCase()) {
        case 'confirmed':
        case 'in_progress':
        case 'on_way':
          active.add(booking);
          break;
        case 'completed':
        case 'cancelled':
          completed.add(booking);
          break;
        case 'pending':
        case 'rescheduled':
        default:
          if (bookingDate != null && bookingDate.isAfter(now.subtract(const Duration(days: 1)))) {
            upcoming.add(booking);
          } else {
            completed.add(booking);
          }
          break;
      }
    }

    setState(() {
      _allBookings = bookings;
      _activeBookings = active;
      _upcomingBookings = upcoming;
      _completedBookings = completed;
    });
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
        return 120; // 2 hours
      case 'deep cleaning':
        return 240; // 4 hours
      case 'premium cleaning':
        return 300; // 5 hours
      case 'move-in/out':
        return 480; // 8 hours
      case 'spring clean':
        return 360; // 6 hours
      default:
        return 120;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            onPressed: _loadBookings,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1CABE3),
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: const Color(0xFF1CABE3),
          labelStyle: GoogleFonts.manrope(fontWeight: FontWeight.w600),
          tabs: [
            Tab(
              text: "Active${_activeBookings.isNotEmpty ? ' (${_activeBookings.length})' : ''}",
            ),
            Tab(
              text: "Upcoming${_upcomingBookings.isNotEmpty ? ' (${_upcomingBookings.length})' : ''}",
            ),
            Tab(
              text: "History${_completedBookings.isNotEmpty ? ' (${_completedBookings.length})' : ''}",
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFF1CABE3)),
      )
          : _allBookings.isEmpty
          ? _buildEmptyState()
          : TabBarView(
        controller: _tabController,
        children: [
          _buildActiveBookingsTab(),
          _buildUpcomingBookingsTab(),
          _buildHistoryTab(),
        ],
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
                // Navigate to booking screen
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1CABE3),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Book Now",
                style: GoogleFonts.manrope(
                  color: Colors.white,
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

  Widget _buildActiveBookingsTab() {
    if (_activeBookings.isEmpty) {
      return _buildNoActiveBookings();
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      color: const Color(0xFF1CABE3),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _activeBookings.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildActiveBookingCard(_activeBookings[index]),
          );
        },
      ),
    );
  }

  Widget _buildUpcomingBookingsTab() {
    if (_upcomingBookings.isEmpty) {
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
      onRefresh: _loadBookings,
      color: const Color(0xFF1CABE3),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _upcomingBookings.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildUpcomingBookingCard(_upcomingBookings[index]),
          );
        },
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_completedBookings.isEmpty) {
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
      onRefresh: _loadBookings,
      color: const Color(0xFF1CABE3),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _completedBookings.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildHistoryBookingCard(_completedBookings[index]),
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
            // Status header with animation
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

            // Service details
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

            // Progress bar
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
                  value: 0.6, // This would be calculated based on actual progress
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

            // Cleaner info
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
                    // Call cleaner functionality
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

            // Action buttons
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
                      _showChatWithCleaner(cleaner);
                    },
                    icon: const Icon(Icons.chat, size: 18),
                    label: Text(
                      "Chat",
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1CABE3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

    DateTime? bookingDateTime;
    if (selectedDate != null) {
      try {
        bookingDateTime = DateTime.parse(selectedDate);
      } catch (e) {
        print("Error parsing date: $selectedDate");
      }
    }

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
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.schedule,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    cleaningType,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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

            // Date and time
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

            // Property details
            Text(
              "$propertyType • $bedrooms bed • $bathrooms bath",
              style: GoogleFonts.manrope(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),

            // Add-ons if any
            if (booking['addOns'] != null) ...[
              const SizedBox(height: 12),
              _buildAddOns(booking['addOns']),
            ],

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showRescheduleDialog(booking),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Reschedule",
                      style: GoogleFonts.manrope(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _confirmBooking(booking),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1CABE3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Confirm",
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
    // Implementation for confirming booking
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Booking confirmed!")),
    );
    _loadBookings();
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
          "Are you sure you want to cancel this booking?",
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
                const SnackBar(content: Text("Booking cancelled")),
              );
              _loadBookings();
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
        content: Text(
          "Contact our support team to reschedule your booking.",
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
        content: Text(
          "Call ${cleaner['phone']}?",
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
                SnackBar(content: Text("Calling ${cleaner['phone']}...")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1CABE3),
            ),
            child: Text(
              "Call",
              style: GoogleFonts.manrope(color: Colors.white),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Opening chat with ${cleaner['name']}...")),
    );
  }

  void _showRateServiceDialog(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Rate Your Service",
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "How was your cleaning service?",
              style: GoogleFonts.manrope(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.star,
                  color: Colors.amber.shade600,
                  size: 32,
                ),
              )),
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
                const SnackBar(content: Text("Thank you for your rating!")),
              );
            },
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
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}