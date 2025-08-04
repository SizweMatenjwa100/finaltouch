// lib/features/payment/data/payment_repository.dart - COMPLETE FIXED VERSION
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class PaymentRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  // PayFast credentials - Use these exact sandbox credentials
  static const String merchantId = "10000100";
  static const String merchantKey = "46f0cd694581a";
  static const String passphrase = "jt7NOE43FZPn";
  static const bool sandboxMode = true;

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

      // Create shortened booking data for PayFast (under 255 chars)
      final shortBookingData = {
        'type': bookingData['cleaningType'] ?? 'Standard',
        'property': bookingData['propertyType'] ?? 'House',
        'rooms': '${bookingData['bedrooms'] ?? 1}bed ${bookingData['bathrooms'] ?? 1}bath',
        'date': bookingData['selectedDate']?.toString().substring(0, 10) ?? '',
        'time': bookingData['selectedTime'] ?? '',
        'locationId': bookingData['locationId'] ?? '',
      };

      // PayFast parameters - EXACT order matters
      final paymentData = <String, String>{
        'merchant_id': merchantId,
        'merchant_key': merchantKey,
        'return_url': _getReturnUrl(),
        'cancel_url': _getCancelUrl(),
        'notify_url': _getNotifyUrl(),
        'name_first': _getFirstName(user),
        'name_last': _getLastName(user),
        'email_address': user.email ?? 'customer@example.com',
        'm_payment_id': paymentId,
        'amount': amount.toStringAsFixed(2),
        'item_name': _getItemName(bookingData),
        'item_description': _getItemDescription(bookingData),
        'custom_str1': user.uid,
        'custom_str2': jsonEncode(shortBookingData),
        'custom_str3': paymentId,
      };

      // Remove empty values (PayFast requirement)
      paymentData.removeWhere((key, value) => value.trim().isEmpty);

      // Ensure custom_str2 is under 255 characters
      if (paymentData['custom_str2']!.length > 255) {
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

      // Save payment record to Firestore
      await _savePaymentRecord(
        paymentId: paymentId,
        userId: user.uid,
        bookingData: bookingData,
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

  /// FIXED: Generate PayFast signature with correct parameter order and encoding
  String _generateSignature(Map<String, String> data) {
    // PayFast requires parameters in this EXACT order
    final orderedKeys = [
      'merchant_id',
      'merchant_key',
      'return_url',
      'cancel_url',
      'notify_url',
      'name_first',
      'name_last',
      'email_address',
      'cell_number',
      'm_payment_id',
      'amount',
      'item_name',
      'item_description',
      'custom_str1',
      'custom_str2',
      'custom_str3',
      'custom_str4',
      'custom_str5',
      'custom_int1',
      'custom_int2',
      'custom_int3',
      'custom_int4',
      'custom_int5',
    ];

    final pairs = <String>[];

    // Build query string in PayFast's required order
    for (final key in orderedKeys) {
      if (data.containsKey(key)) {
        final value = data[key]!.trim();
        if (value.isNotEmpty) {
          // URL encode the value, replace %20 with +
          final encodedValue = Uri.encodeQueryComponent(value).replaceAll('%20', '+');
          pairs.add('$key=$encodedValue');
        }
      }
    }

    String queryString = pairs.join('&');

    // Add passphrase for sandbox (CRITICAL!)
    if (sandboxMode && passphrase.isNotEmpty) {
      queryString += '&passphrase=$passphrase';
    }

    print("🔐 Signature string: $queryString");

    // Generate MD5 hash
    final bytes = utf8.encode(queryString);
    final digest = md5.convert(bytes);

    final signature = digest.toString();
    print("🔐 Generated signature: $signature");

    return signature;
  }

  /// Generate PayFast payment URL
  String _generatePaymentUrl(Map<String, String> data) {
    final baseUrl = sandboxMode
        ? 'https://sandbox.payfast.co.za/eng/process'
        : 'https://www.payfast.co.za/eng/process';

    // For the URL, we need to URL encode the values
    final queryParams = data.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    final fullUrl = '$baseUrl?$queryParams';
    print("🌐 PayFast URL length: ${fullUrl.length}");
    print("🌐 PayFast URL: ${fullUrl.substring(0, fullUrl.length > 200 ? 200 : fullUrl.length)}...");

    return fullUrl;
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
        'status': 'confirmed',
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

  /// Save payment record to Firestore
  Future<void> _savePaymentRecord({
    required String paymentId,
    required String userId,
    required Map<String, dynamic> bookingData,
    required double amount,
    required String currency,
    required Map<String, String> paymentData,
    required DateTime timestamp,
  }) async {
    await firestore.collection('payments').doc(paymentId).set({
      'paymentId': paymentId,
      'userId': userId,
      'bookingData': jsonEncode(bookingData),
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