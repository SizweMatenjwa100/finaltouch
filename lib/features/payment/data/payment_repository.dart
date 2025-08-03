// lib/features/payment/data/payment_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  PaymentRepository({
    required this.firestore,
    required this.auth,
  });

  /// Save payment record to Firestore
  Future<String> savePaymentRecord({
    required String bookingId,
    required String merchantOrderId,
    required double amount,
    required String status,
    required Map<String, dynamic> paymentData,
  }) async {
    final user = auth.currentUser;
    if (user == null) {
      throw Exception("User not authenticated");
    }

    try {
      // Convert paymentData to proper format for Firestore
      final Map<String, Object> firestoreData = {
        'bookingId': bookingId,
        'merchantOrderId': merchantOrderId,
        'amount': amount,
        'status': status,
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Safely convert paymentData
      paymentData.forEach((key, value) {
        if (value != null) {
          if (value is Map<String, dynamic>) {
            // Convert nested maps
            final Map<String, Object> nestedMap = {};
            value.forEach((nestedKey, nestedValue) {
              if (nestedValue != null) {
                nestedMap[nestedKey] = nestedValue as Object;
              }
            });
            firestoreData[key] = nestedMap;
          } else {
            firestoreData[key] = value as Object;
          }
        }
      });

      final paymentDoc = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('payments')
          .add(firestoreData);

      print("✅ Payment record saved with ID: ${paymentDoc.id}");
      return paymentDoc.id;
    } catch (e) {
      print("❌ Error saving payment record: $e");
      rethrow;
    }
  }

  /// Create booking after successful payment
  Future<void> _createBookingAfterPayment(Map<String, dynamic> paymentRecord, String bookingId) async {
    final user = auth.currentUser;
    if (user == null) {
      throw Exception("User not authenticated");
    }

    try {
      print("🏗️ Creating booking after successful payment");

      final paymentData = paymentRecord['paymentData'] as Map<String, dynamic>;
      final locationId = paymentData['locationId'] as String;

      print("📍 Location ID: $locationId");
      print("🆔 Booking ID: $bookingId");

      // Create the booking with confirmed status
      final bookingData = <String, Object>{
        'userId': user.uid,
        'userEmail': user.email ?? '',
        'propertyType': paymentData['propertyType'] ?? '',
        'bedrooms': paymentData['bedrooms'] ?? 1,
        'bathrooms': paymentData['bathrooms'] ?? 1,
        'cleaningType': paymentData['cleaningType'] ?? '',
        'addOns': paymentData['addOns'] ?? {},
        'selectedDate': paymentData['selectedDate'] ?? '',
        'selectedTime': paymentData['selectedTime'] ?? '',
        'sameCleaner': paymentData['sameCleaner'] ?? false,
        'status': 'confirmed', // Booking is confirmed after payment
        'paymentStatus': 'complete',
        'totalPrice': paymentData['totalPrice'] ?? 0.0,
        'priceBreakdown': paymentData['priceBreakdown'] ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'timestamp': FieldValue.serverTimestamp(),
        'locationId': locationId,
        'notes': '',
      };

      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('locations')
          .doc(locationId)
          .collection('bookings')
          .doc(bookingId)
          .set(bookingData);

      print("✅ Booking created successfully in Firestore: $bookingId");

    } catch (e) {
      print("❌ Error creating booking after payment: $e");
      rethrow;
    }
  }

  /// Update payment status
  Future<void> updatePaymentStatus({
    required String paymentId,
    required String status,
    Map<String, dynamic>? additionalData,
  }) async {
    final user = auth.currentUser;
    if (user == null) {
      throw Exception("User not authenticated");
    }

    try {
      final updateData = <String, Object>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (additionalData != null) {
        // Convert additionalData to Map<String, Object>
        additionalData.forEach((key, value) {
          if (value != null) {
            updateData[key] = value as Object;
          }
        });
      }

      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('payments')
          .doc(paymentId)
          .update(updateData);

      print("✅ Payment status updated to: $status");
    } catch (e) {
      print("❌ Error updating payment status: $e");
      rethrow;
    }
  }

  /// Get payment by merchant order ID
  Future<Map<String, dynamic>?> getPaymentByOrderId(String merchantOrderId) async {
    final user = auth.currentUser;
    if (user == null) {
      throw Exception("User not authenticated");
    }

    try {
      final querySnapshot = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('payments')
          .where('merchantOrderId', isEqualTo: merchantOrderId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        data['paymentId'] = doc.id;
        return data;
      }

      return null;
    } catch (e) {
      print("❌ Error getting payment by order ID: $e");
      return null;
    }
  }

  /// Get user's payment history
  Future<List<Map<String, dynamic>>> getUserPayments() async {
    final user = auth.currentUser;
    if (user == null) {
      throw Exception("User not authenticated");
    }

    try {
      final querySnapshot = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('payments')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['paymentId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print("❌ Error getting user payments: $e");
      return [];
    }
  }

  /// Update booking payment status
  Future<void> updateBookingPaymentStatus({
    required String bookingId,
    required String paymentStatus,
    required String locationId,
  }) async {
    final user = auth.currentUser;
    if (user == null) {
      throw Exception("User not authenticated");
    }

    try {
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('locations')
          .doc(locationId)
          .collection('bookings')
          .doc(bookingId)
          .update(<String, Object>{
        'paymentStatus': paymentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print("✅ Booking payment status updated to: $paymentStatus");
    } catch (e) {
      print("❌ Error updating booking payment status: $e");
      rethrow;
    }
  }

  /// Process payment callback from PayFast
  Future<void> processPaymentCallback({
    required String merchantOrderId,
    required String paymentStatus,
    required Map<String, dynamic> callbackData,
  }) async {
    try {
      // Find the payment record
      final paymentRecord = await getPaymentByOrderId(merchantOrderId);
      if (paymentRecord == null) {
        throw Exception("Payment record not found for order: $merchantOrderId");
      }

      final paymentId = paymentRecord['paymentId'] as String;
      final bookingId = paymentRecord['bookingId'] as String;

      // Update payment status
      await updatePaymentStatus(
        paymentId: paymentId,
        status: paymentStatus,
        additionalData: {
          'callbackData': callbackData,
          'callbackReceivedAt': FieldValue.serverTimestamp(),
        },
      );

      // Update booking status based on payment
      String bookingStatus;
      switch (paymentStatus.toLowerCase()) {
        case 'complete':
          bookingStatus = 'confirmed';
          break;
        case 'failed':
        case 'cancelled':
          bookingStatus = 'payment_failed';
          break;
        default:
          bookingStatus = 'pending_payment';
      }

      // Note: We would need the locationId to update booking
      // For now, we'll store it in the payment record during creation
      final locationId = paymentRecord['locationId'] as String?;
      if (locationId != null) {
        await updateBookingPaymentStatus(
          bookingId: bookingId,
          paymentStatus: paymentStatus,
          locationId: locationId,
        );
      }

      print("✅ Payment callback processed successfully");
    } catch (e) {
      print("❌ Error processing payment callback: $e");
      rethrow;
    }
  }
}