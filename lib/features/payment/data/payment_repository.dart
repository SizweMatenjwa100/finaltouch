// lib/features/payment/data/payment_repository.dart
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class PaymentRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  // PayFast credentials - Replace with your actual credentials
  static const String merchantId = "10000100"; // Replace with your merchant ID
  static const String merchantKey = "46f0cd694581a"; // Replace with your merchant key
  static const String passphrase = ""; // Empty for sandbox, set for production
  static const bool sandboxMode = true; // Set to false for production

  PaymentRepository({
    required this.auth,
    required this.firestore,
  });

  /// Generate PayFast payment URL and data
  Future<Map<String, dynamic>> initializePayment({
    required Map<String, dynamic> bookingData,
    required double amount,
    required String currency,
  }) async {
    try {
      final user = auth.currentUser;
      if (user == null) {
        throw Exception("User must be authenticated to make payments");
      }

      // Generate unique payment ID
      final paymentId = _generatePaymentId();
      final timestamp = DateTime.now();

      // Create a shortened version of booking data for PayFast (under 255 chars)
      final shortBookingData = {
        'type': bookingData['cleaningType'] ?? 'Standard',
        'property': bookingData['propertyType'] ?? 'House',
        'rooms': '${bookingData['bedrooms'] ?? 1}bed ${bookingData['bathrooms'] ?? 1}bath',
        'date': bookingData['selectedDate']?.toString().substring(0, 10) ?? '',
        'time': bookingData['selectedTime'] ?? '',
        'locationId': bookingData['locationId'] ?? '',
      };

      // Prepare PayFast data
      final paymentData = {
        'merchant_id': merchantId,
        'merchant_key': merchantKey,
        'return_url': _getReturnUrl(),
        'cancel_url': _getCancelUrl(),
        'notify_url': _getNotifyUrl(),
        'name_first': _getFirstName(user),
        'name_last': _getLastName(user),
        'email_address': user.email ?? '',
        'cell_number': '', // Add if you collect phone numbers
        'm_payment_id': paymentId,
        'amount': amount.toStringAsFixed(2),
        'item_name': _getItemName(bookingData),
        'item_description': _getItemDescription(bookingData),
        'custom_str1': user.uid, // User ID for reference
        'custom_str2': jsonEncode(shortBookingData), // Shortened booking data (under 255 chars)
        'custom_str3': paymentId, // Payment reference
      };

      // Ensure custom_str2 is under 255 characters
      if (paymentData['custom_str2']!.length > 255) {
        // If still too long, use minimal data
        final minimalData = {
          'paymentId': paymentId,
          'userId': user.uid,
          'locationId': bookingData['locationId'] ?? '',
        };
        paymentData['custom_str2'] = jsonEncode(minimalData);
      }

      print("📝 PayFast custom_str2 length: ${paymentData['custom_str2']!.length}");
      print("📝 PayFast custom_str2 content: ${paymentData['custom_str2']}");

      // Generate signature
      final signature = _generateSignature(paymentData);
      paymentData['signature'] = signature;

      // Generate PayFast URL
      final paymentUrl = _generatePaymentUrl(paymentData);

      // Save payment record to Firestore (with full booking data)
      await _savePaymentRecord(
        paymentId: paymentId,
        userId: user.uid,
        bookingData: bookingData, // Save full data to Firestore
        amount: amount,
        currency: currency,
        paymentData: paymentData,
        timestamp: timestamp,
      );

      return {
        'paymentId': paymentId,
        'paymentUrl': paymentUrl,
        'paymentData': paymentData,
      };
    } catch (e) {
      print("❌ Error initializing payment: $e");
      rethrow;
    }
  }

  /// Process successful payment and save booking
  Future<String> processSuccessfulPayment({
    required String paymentId,
    required String paymentToken,
    required Map<String, dynamic> paymentDetails,
  }) async {
    try {
      final user = auth.currentUser;
      if (user == null) {
        throw Exception("User must be authenticated");
      }

      // Get payment record
      final paymentDoc = await firestore
          .collection('payments')
          .doc(paymentId)
          .get();

      if (!paymentDoc.exists) {
        throw Exception("Payment record not found");
      }

      final paymentData = paymentDoc.data()!;
      final bookingData = Map<String, dynamic>.from(
        jsonDecode(paymentData['bookingData']),
      );

      // Update payment status
      await firestore.collection('payments').doc(paymentId).update({
        'status': 'completed',
        'paymentToken': paymentToken,
        'paymentDetails': paymentDetails,
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Save booking to bookings collection
      final locationId = await _getUserLocationId();
      if (locationId == null) {
        throw Exception("User location not found");
      }

      // Prepare complete booking data
      final completeBookingData = {
        ...bookingData,
        'paymentId': paymentId,
        'paymentStatus': 'paid',
        'totalAmount': paymentData['amount'],
        'currency': paymentData['currency'],
        'status': 'confirmed', // Confirmed since payment is successful
        'paidAt': FieldValue.serverTimestamp(),
      };

      // Save to bookings collection
      final bookingRef = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('locations')
          .doc(locationId)
          .collection('bookings')
          .add(completeBookingData);

      print("✅ Booking saved successfully: ${bookingRef.id}");
      print("💰 Payment processed successfully: $paymentId");

      return bookingRef.id;
    } catch (e) {
      print("❌ Error processing payment: $e");
      rethrow;
    }
  }

  /// Handle failed payment
  Future<void> processFailedPayment({
    required String paymentId,
    required String error,
  }) async {
    try {
      await firestore.collection('payments').doc(paymentId).update({
        'status': 'failed',
        'error': error,
        'failedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print("💥 Payment failed: $paymentId - $error");
    } catch (e) {
      print("❌ Error updating failed payment: $e");
      rethrow;
    }
  }

  /// Get user's location ID
  Future<String?> _getUserLocationId() async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return null;

    try {
      final locationsSnapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('locations')
          .limit(1)
          .get();

      if (locationsSnapshot.docs.isNotEmpty) {
        return locationsSnapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      print("❌ Error getting location: $e");
      return null;
    }
  }

  /// Generate unique payment ID
  String _generatePaymentId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999);
    return 'PAY_${timestamp}_$random';
  }

  /// Generate PayFast signature
  String _generateSignature(Map<String, dynamic> data) {
    // Remove signature if it exists
    final dataToSign = Map<String, dynamic>.from(data);
    dataToSign.remove('signature');

    // Sort keys alphabetically
    final sortedKeys = dataToSign.keys.toList()..sort();
    final pairs = <String>[];

    // Build query string with proper encoding
    for (final key in sortedKeys) {
      final value = dataToSign[key].toString().trim();
      if (value.isNotEmpty) {
        // URL encode both key and value
        final encodedKey = Uri.encodeQueryComponent(key);
        final encodedValue = Uri.encodeQueryComponent(value);
        pairs.add('$encodedKey=$encodedValue');
      }
    }

    String queryString = pairs.join('&');

    // Add passphrase for sandbox mode
    if (sandboxMode && passphrase.isNotEmpty) {
      queryString += '&passphrase=${Uri.encodeQueryComponent(passphrase)}';
    }

    print("🔐 Signature query string: $queryString");

    // Generate MD5 hash
    final bytes = utf8.encode(queryString);
    final digest = md5.convert(bytes);

    final signature = digest.toString();
    print("🔐 Generated signature: $signature");

    return signature;
  }

  /// Generate PayFast payment URL
  String _generatePaymentUrl(Map<String, dynamic> data) {
    final baseUrl = sandboxMode
        ? 'https://sandbox.payfast.co.za/eng/process'
        : 'https://www.payfast.co.za/eng/process';

    // Build query parameters with proper encoding
    final queryParams = data.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value.toString())}')
        .join('&');

    final fullUrl = '$baseUrl?$queryParams';
    print("🌐 PayFast URL length: ${fullUrl.length}");
    print("🌐 PayFast URL: ${fullUrl.substring(0, fullUrl.length > 200 ? 200 : fullUrl.length)}...");

    return fullUrl;
  }

  /// Save payment record to Firestore
  Future<void> _savePaymentRecord({
    required String paymentId,
    required String userId,
    required Map<String, dynamic> bookingData,
    required double amount,
    required String currency,
    required Map<String, dynamic> paymentData,
    required DateTime timestamp,
  }) async {
    await firestore.collection('payments').doc(paymentId).set({
      'paymentId': paymentId,
      'userId': userId,
      'bookingData': jsonEncode(bookingData), // Store full booking data in Firestore
      'amount': amount,
      'currency': currency,
      'status': 'pending',
      'paymentMethod': 'payfast',
      'paymentData': paymentData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print("💾 Payment record saved with full booking data");
  }

  // Helper methods for PayFast data
  String _getReturnUrl() => 'https://yourapp.com/payment/success';
  String _getCancelUrl() => 'https://yourapp.com/payment/cancel';
  String _getNotifyUrl() => 'https://yourapp.com/payment/notify';

  String _getFirstName(User user) {
    final displayName = user.displayName ?? '';
    if (displayName.isNotEmpty) {
      return displayName.split(' ').first;
    }
    return 'Customer';
  }

  String _getLastName(User user) {
    final displayName = user.displayName ?? '';
    if (displayName.isNotEmpty) {
      final parts = displayName.split(' ');
      return parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }
    return '';
  }

  String _getItemName(Map<String, dynamic> bookingData) {
    final cleaningType = bookingData['cleaningType'] ?? 'Cleaning Service';
    return cleaningType;
  }

  String _getItemDescription(Map<String, dynamic> bookingData) {
    final cleaningType = bookingData['cleaningType'] ?? 'Cleaning Service';
    final propertyType = bookingData['propertyType'] ?? '';
    final bedrooms = bookingData['bedrooms'] ?? 1;
    final bathrooms = bookingData['bathrooms'] ?? 1;

    return '$cleaningType for $propertyType ($bedrooms bed, $bathrooms bath)';
  }
}