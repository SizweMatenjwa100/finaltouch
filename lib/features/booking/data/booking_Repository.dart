import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  BookingRepository({required this.auth, required this.firestore});

  Future<void> saveBooking(Map<String, dynamic> bookingData) async {
    // 1. Check if user is authenticated
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      throw Exception("User must be authenticated to create bookings");
    }

    final uid = currentUser.uid;
    print("🔐 User authenticated: $uid");

    try {
      // 2. Get locationId from booking data (passed from schedule module)
      final locationId = bookingData['locationId'];
      if (locationId == null || locationId.isEmpty) {
        throw Exception("Location ID is required to save booking");
      }

      print("📍 Using provided location: $locationId");

      // 3. Prepare complete booking data
      final completeBookingData = {
        // User Information
        'userId': uid,
        'userEmail': currentUser.email ?? '',

        // Property Details
        'propertyType': bookingData['propertyType'] ?? '',
        'bedrooms': bookingData['bedrooms'] ?? 1,
        'bathrooms': bookingData['bathrooms'] ?? 1,

        // Service Details
        'cleaningType': bookingData['cleaningType'] ?? '',
        'addOns': bookingData['addOns'] ?? {},

        // Schedule Details
        'selectedDate': bookingData['selectedDate'] ?? '',
        'selectedTime': bookingData['selectedTime'] ?? '',
        'sameCleaner': bookingData['sameCleaner'] ?? false,

        // Booking Metadata
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
        'timestamp': FieldValue.serverTimestamp(),
        'locationId': locationId,

        // Additional Info
        'notes': bookingData['notes'] ?? '',
      };

      print("💾 Saving booking data: $completeBookingData");

      // 4. Save to Firestore: users/{uid}/locations/{locationId}/bookings
      final docRef = await firestore
          .collection('users')
          .doc(uid)
          .collection('locations')
          .doc(locationId)
          .collection('bookings')
          .add(completeBookingData);

      print("✅ Booking saved successfully with ID: ${docRef.id}");

    } catch (e) {
      print("❌ Error saving booking: $e");
      rethrow;
    }
  }

  // ADD THIS METHOD - This is what's missing!
  Future<String?> getUserLocationId() async {
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

  // Get all bookings for the authenticated user
  Future<List<Map<String, dynamic>>> getUserBookings() async {
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      throw Exception("User must be authenticated");
    }

    try {
      final locationId = await getUserLocationId();
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
}