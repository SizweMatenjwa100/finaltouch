// lib/features/booking/showBooking/data/booking_display_repository.dart - FINAL FIX
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingDisplayRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  BookingDisplayRepository({required this.auth, required this.firestore});

  Future<List<Map<String, dynamic>>> getUserBookings() async {
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      throw Exception("User must be authenticated");
    }

    final allBookings = <Map<String, dynamic>>[];

    try {
      print("🔍 DEBUG: Getting bookings for user: $uid");

      // METHOD 1: Check regular bookings structure
      print("📋 METHOD 1: Checking regular bookings...");
      final locationsSnapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('locations')
          .get();

      print("📍 Found ${locationsSnapshot.docs.length} locations");

      for (final locationDoc in locationsSnapshot.docs) {
        print("📍 Checking location: ${locationDoc.id}");
        final bookingsSnapshot = await firestore
            .collection('users')
            .doc(uid)
            .collection('locations')
            .doc(locationDoc.id)
            .collection('bookings')
            .get();

        print("📋 Location ${locationDoc.id}: ${bookingsSnapshot.docs.length} bookings");

        for (final bookingDoc in bookingsSnapshot.docs) {
          final data = bookingDoc.data();
          data['bookingId'] = bookingDoc.id;
          data['source'] = 'regular';
          allBookings.add(data);
          print("   ✅ Added regular booking: ${bookingDoc.id}");
        }
      }

      // METHOD 2: Check completed payments
      print("\n💳 METHOD 2: Checking completed payments...");
      final paymentsSnapshot = await firestore
          .collection('payments')
          .where('userId', isEqualTo: uid)
          .get();

      print("💳 Found ${paymentsSnapshot.docs.length} total payments");

      for (final paymentDoc in paymentsSnapshot.docs) {
        final paymentData = paymentDoc.data();
        final status = paymentData['status'];

        print("💳 Payment ${paymentDoc.id}: status = $status");

        if (status == 'completed' && paymentData['bookingData'] != null) {
          try {
            final bookingData = Map<String, dynamic>.from(
                jsonDecode(paymentData['bookingData']));

            // Check if already exists
            final existingBooking = allBookings.any((booking) =>
            booking['paymentId'] == paymentDoc.id);

            if (!existingBooking) {
              bookingData.addAll({
                'bookingId': paymentDoc.id,
                'paymentId': paymentDoc.id,
                'status': 'confirmed',
                'paymentStatus': 'paid',
                'totalAmount': paymentData['amount'],
                'currency': paymentData['currency'] ?? 'ZAR',
                'source': 'payment',
                'userId': uid,
              });

              // Handle timestamp
              if (paymentData['createdAt'] != null) {
                bookingData['createdAt'] = paymentData['createdAt'];
                bookingData['timestamp'] = paymentData['createdAt'];
              }

              allBookings.add(bookingData);
              print("   ✅ Added payment booking: ${paymentDoc.id}");
            } else {
              print("   ⚠️ Skipping payment ${paymentDoc.id} (already exists)");
            }
          } catch (e) {
            print("   ❌ Error parsing payment booking data: $e");
          }
        } else {
          print("   ⚠️ Skipping payment ${paymentDoc.id} (status: $status, hasBookingData: ${paymentData['bookingData'] != null})");
        }
      }

      // METHOD 3: Direct search in root bookings collection (fallback)
      print("\n📋 METHOD 3: Checking root bookings collection...");
      try {
        final rootBookingsSnapshot = await firestore
            .collection('bookings')
            .where('userId', isEqualTo: uid)
            .get();

        print("📋 Found ${rootBookingsSnapshot.docs.length} bookings in root collection");

        for (final bookingDoc in rootBookingsSnapshot.docs) {
          final data = bookingDoc.data();
          data['bookingId'] = bookingDoc.id;
          data['source'] = 'root';

          // Check if already exists
          final existingBooking = allBookings.any((booking) =>
          booking['bookingId'] == bookingDoc.id);

          if (!existingBooking) {
            allBookings.add(data);
            print("   ✅ Added root booking: ${bookingDoc.id}");
          }
        }
      } catch (e) {
        print("   ⚠️ Root bookings collection doesn't exist or error: $e");
      }

      // METHOD 4: Check user document for embedded bookings
      print("\n👤 METHOD 4: Checking user document...");
      try {
        final userDoc = await firestore.collection('users').doc(uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          print("👤 User document exists with keys: ${userData.keys}");

          if (userData['bookings'] != null) {
            final userBookings = userData['bookings'] as List;
            print("👤 Found ${userBookings.length} bookings in user document");

            for (int i = 0; i < userBookings.length; i++) {
              final booking = Map<String, dynamic>.from(userBookings[i]);
              booking['bookingId'] = 'user_$i';
              booking['source'] = 'user_doc';
              allBookings.add(booking);
              print("   ✅ Added user doc booking: user_$i");
            }
          }
        }
      } catch (e) {
        print("   ⚠️ Error checking user document: $e");
      }

      print("\n📊 SUMMARY:");
      print("📋 Total bookings found: ${allBookings.length}");

      for (int i = 0; i < allBookings.length; i++) {
        final booking = allBookings[i];
        print("📋 Booking $i:");
        print("   - ID: ${booking['bookingId']}");
        print("   - Source: ${booking['source']}");
        print("   - Status: ${booking['status']}");
        print("   - Date: ${booking['selectedDate']}");
        print("   - Type: ${booking['cleaningType']}");
        print("   - Payment ID: ${booking['paymentId']}");
      }

      return allBookings;

    } catch (e) {
      print("❌ CRITICAL ERROR getting bookings: $e");
      print("🔍 Stack trace: ${StackTrace.current}");
      rethrow;
    }
  }

  // Keep all other methods the same
  Future<List<Map<String, dynamic>>> getBookingsByStatus(String status) async {
    final allBookings = await getUserBookings();
    return allBookings.where((booking) =>
    booking['status']?.toString().toLowerCase() == status.toLowerCase()).toList();
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      throw Exception("User must be authenticated");
    }

    try {
      final locationId = await _getUserLocationId();
      if (locationId == null) {
        throw Exception("No location found for user");
      }

      await firestore
          .collection('users')
          .doc(uid)
          .collection('locations')
          .doc(locationId)
          .collection('bookings')
          .doc(bookingId)
          .update({
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      print("✅ Updated booking $bookingId status to $status");

    } catch (e) {
      print("❌ Error updating booking status: $e");
      rethrow;
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    await updateBookingStatus(bookingId, 'cancelled');
  }

  Future<Map<String, dynamic>?> getBookingById(String bookingId) async {
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      throw Exception("User must be authenticated");
    }

    try {
      final locationId = await _getUserLocationId();
      if (locationId == null) {
        return null;
      }

      final doc = await firestore
          .collection('users')
          .doc(uid)
          .collection('locations')
          .doc(locationId)
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        data['bookingId'] = doc.id;
        return data;
      }
      return null;

    } catch (e) {
      print("❌ Error getting booking: $e");
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getUpcomingBookings() async {
    final allBookings = await getUserBookings();
    final now = DateTime.now();

    return allBookings.where((booking) {
      final dateString = booking['selectedDate'] as String?;
      if (dateString == null) return false;

      try {
        final bookingDate = DateTime.parse(dateString);
        return bookingDate.isAfter(now.subtract(const Duration(days: 1)));
      } catch (e) {
        return false;
      }
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getPastBookings() async {
    final allBookings = await getUserBookings();
    final now = DateTime.now();

    return allBookings.where((booking) {
      final dateString = booking['selectedDate'] as String?;
      if (dateString == null) return false;

      try {
        final bookingDate = DateTime.parse(dateString);
        return bookingDate.isBefore(now);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  Future<String?> _getUserLocationId() async {
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      throw Exception("User must be authenticated");
    }

    try {
      final locationsSnapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('locations')
          .limit(1)
          .get();

      if (locationsSnapshot.docs.isNotEmpty) {
        final locationId = locationsSnapshot.docs.first.id;
        print("📍 Found location ID: $locationId");
        return locationId;
      } else {
        print("⚠️ No locations found for user");
        return null;
      }
    } catch (e) {
      print("❌ Error getting location: $e");
      rethrow;
    }
  }
}