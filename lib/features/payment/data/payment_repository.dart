// lib/features/payment/data/payment_repository.dart - PRODUCTION VERSION WITH CLOUD FUNCTIONS
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import 'package:cloud_functions/cloud_functions.dart';

class PaymentRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final FirebaseFunctions functions;

  // Production PayFast Configuration
  static const String merchantId = "10041473";
  static const String merchantKey = "qrs8b5w5uroiq";
  static const String passphrase = "";
  static const bool sandboxMode = false; // Set to false for production

  // Your deployed Cloud Function URL

  static const String itnUrl = "https://payfastitn-5qmz3ymkpa-uc.a.run.app";

  PaymentRepository({
    required this.auth,
    required this.firestore,
    required this.functions,
  });

  /// Initialize payment with proper ITN webhook setup
  Future<Map<String, dynamic>> initializePayment({
    required Map<String, dynamic> bookingData,
    required double amount,
    required String currency,
  }) async {
    try {
      final user = auth.currentUser;
      if (user == null) throw Exception("User must be authenticated");

      final paymentId = _generatePaymentId();

      print("🆔 Payment ID: $paymentId");
      print("💰 Amount: $amount");
      print("🔗 ITN URL: $itnUrl");

      // PayFast payment data with ITN webhook
      final paymentData = <String, String>{
        'merchant_id': merchantId,
        'merchant_key': merchantKey,
        'return_url': 'https://yourapp.com/payment/return',
        'cancel_url': 'https://yourapp.com/payment/cancel',
        'notify_url': itnUrl, // Your Cloud Function endpoint
        'name_first': user.displayName?.split(' ').first ?? 'Customer',
        'name_last': user.displayName?.split(' ').skip(1).join(' ') ?? '',
        'email_address': user.email ?? 'customer@example.com',
        'm_payment_id': paymentId,
        'amount': amount.toStringAsFixed(2),
        'item_name': bookingData['cleaningType'] ?? 'Cleaning Service',
        'item_description': 'Professional cleaning service - ${bookingData['propertyType'] ?? 'Property'}',
        'custom_str1': user.uid,
        'custom_str2': paymentId,
        'custom_str3': 'production_processing',
      };

      // Remove empty values and generate signature
      paymentData.removeWhere((key, value) => value.trim().isEmpty);
      final signature = _generateSignature(paymentData);
      paymentData['signature'] = signature;
      final paymentUrl = _generatePaymentUrl(paymentData);

      // Save payment record to Firestore
      await firestore.collection('payments').doc(paymentId).set({
        'paymentId': paymentId,
        'userId': user.uid,
        'userEmail': user.email ?? '',
        'bookingData': jsonEncode(bookingData),
        'amount': amount,
        'currency': currency,
        'status': 'pending',
        'paymentMethod': 'payfast_itn',
        'merchantId': merchantId,
        'expectedAmount': amount, // For validation
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),

        // Metadata
        'clientInfo': {
          'platform': 'flutter',
          'version': '1.0.0',
          'timestamp': DateTime.now().toIso8601String(),
        }
      });

      print("✅ Payment initialized with ITN webhook");

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

  /// Monitor payment status with real-time updates
  Stream<PaymentStatus> monitorPaymentStatus(String paymentId) {
    return firestore
        .collection('payments')
        .doc(paymentId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return PaymentStatus.notFound;
      }

      final data = doc.data()!;
      final status = data['status'] as String;

      switch (status) {
        case 'pending':
          return PaymentStatus.pending;
        case 'completed':
          return PaymentStatus.completed;
        case 'failed':
          return PaymentStatus.failed;
        case 'cancelled':
          return PaymentStatus.cancelled;
        default:
          return PaymentStatus.unknown;
      }
    });
  }

  /// Get payment details
  Future<Map<String, dynamic>?> getPaymentDetails(String paymentId) async {
    try {
      final doc = await firestore.collection('payments').doc(paymentId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print("❌ Error getting payment details: $e");
      return null;
    }
  }

  /// Verify payment status manually (fallback)
  Future<PaymentVerificationResult> verifyPayment(String paymentId) async {
    try {
      print("🔍 Verifying payment: $paymentId");

      // Call Cloud Function to verify payment
      final callable = functions.httpsCallable('verifyPayment');
      final result = await callable.call({'paymentId': paymentId});

      final data = result.data as Map<String, dynamic>;

      return PaymentVerificationResult(
        paymentId: data['paymentId'],
        status: data['status'],
        amount: (data['amount'] as num).toDouble(),
        verified: data['status'] == 'completed',
        message: 'Payment verification completed',
      );

    } catch (e) {
      print("❌ Payment verification failed: $e");
      return PaymentVerificationResult(
        paymentId: paymentId,
        status: 'unknown',
        amount: 0,
        verified: false,
        message: 'Verification failed: ${e.toString()}',
      );
    }
  }

  /// Get user bookings with real-time updates
  Stream<List<Map<String, dynamic>>> getUserBookings() {
    final uid = auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return firestore
        .collectionGroup('bookings')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Cancel payment
  Future<void> cancelPayment(String paymentId, String reason) async {
    try {
      await firestore.collection('payments').doc(paymentId).update({
        'status': 'cancelled',
        'cancellationReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      print("🚫 Payment cancelled: $paymentId");
    } catch (e) {
      print("❌ Error cancelling payment: $e");
      rethrow;
    }
  }

  /// Test Cloud Function connection
  Future<Map<String, dynamic>> testCloudFunctionConnection() async {
    try {
      final callable = functions.httpsCallable('payfastHealthCheck');
      final result = await callable.call();
      return result.data as Map<String, dynamic>;
    } catch (e) {
      print("❌ Cloud Function connection failed: $e");
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  /// Generate secure signature for PayFast
  String _generateSignature(Map<String, String> data) {
    final orderedKeys = [
      'merchant_id', 'merchant_key', 'return_url', 'cancel_url', 'notify_url',
      'name_first', 'name_last', 'email_address', 'm_payment_id', 'amount',
      'item_name', 'item_description', 'custom_str1', 'custom_str2', 'custom_str3',
    ];

    final pairs = <String>[];
    for (final key in orderedKeys) {
      if (data.containsKey(key) && data[key]!.trim().isNotEmpty) {
        final encodedValue = Uri.encodeQueryComponent(data[key]!).replaceAll('%20', '+');
        pairs.add('$key=$encodedValue');
      }
    }

    String queryString = pairs.join('&');
    if (sandboxMode && passphrase.isNotEmpty) {
      queryString += '&passphrase=$passphrase';
    }

    final bytes = utf8.encode(queryString);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// Generate PayFast payment URL
  String _generatePaymentUrl(Map<String, String> data) {
    final baseUrl = sandboxMode
        ? 'https://sandbox.payfast.co.za/eng/process'
        : 'https://www.payfast.co.za/eng/process';

    final queryParams = data.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    return '$baseUrl?$queryParams';
  }

  /// Generate unique payment ID
  String _generatePaymentId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999);
    return 'PAY_${timestamp}_$random';
  }

  // LEGACY SUPPORT - These methods are now handled by Cloud Functions
  @Deprecated('This method is now handled by Cloud Functions ITN webhook')
  Future<String> processSuccessfulPayment({
    required String paymentId,
    required String paymentToken,
    required Map<String, dynamic> paymentDetails,
  }) async {
    throw Exception("Payment processing is now handled by Cloud Functions ITN webhook");
  }

  @Deprecated('This method is now handled by Cloud Functions ITN webhook')
  Future<void> processFailedPayment({
    required String paymentId,
    required String error,
  }) async {
    throw Exception("Failed payment processing is now handled by Cloud Functions ITN webhook");
  }
}

/// Payment status enum
enum PaymentStatus {
  pending,
  completed,
  failed,
  cancelled,
  notFound,
  unknown,
}

/// Payment verification result
class PaymentVerificationResult {
  final String paymentId;
  final String status;
  final double amount;
  final bool verified;
  final String message;

  PaymentVerificationResult({
    required this.paymentId,
    required this.status,
    required this.amount,
    required this.verified,
    required this.message,
  });
}