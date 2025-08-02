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

    try {
      final locationId = await _getUserLocationId();
      if (locationId == null) {
        return []; // No location, no bookings
      }

      final snapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('locations')
          .doc(locationId)
          .collection('bookings')
          .orderBy('timestamp', descending: true)
          .get();

      final bookings = snapshot.docs.map((doc) {
        final data = doc.data();
        data['bookingId'] = doc.id;
        return data;
      }).toList();

      print("📋 Found ${bookings.length} bookings for user");
      return bookings;

    } catch (e) {
      print("❌ Error getting bookings: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getBookingsByStatus(String status) async {
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      throw Exception("User must be authenticated");
    }

    try {
      final locationId = await _getUserLocationId();
      if (locationId == null) {
        return [];
      }

      final snapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('locations')
          .doc(locationId)
          .collection('bookings')
          .where('status', isEqualTo: status)
          .orderBy('timestamp', descending: true)
          .get();

      final bookings = snapshot.docs.map((doc) {
        final data = doc.data();
        data['bookingId'] = doc.id;
        return data;
      }).toList();

      print("📋 Found ${bookings.length} $status bookings");
      return bookings;

    } catch (e) {
      print("❌ Error getting $status bookings: $e");
      return [];
    }
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

  // Private helper method
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