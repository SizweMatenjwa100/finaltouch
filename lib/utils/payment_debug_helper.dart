// lib/utils/payment_debug_helper.dart - PAYMENT DEBUGGING UTILITIES
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class PaymentDebugHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Test your Cloud Function health
  static Future<void> testCloudFunctionHealth() async {
    try {
      // You can test this URL directly in your browser or via curl
      const String healthUrl = 'https://payfastitn-5qmz3ymkpa-uc.a.run.app/payfastHealthCheck';

      debugPrint('🔧 Test your Cloud Function health at: $healthUrl');
      debugPrint('💡 Expected response: {"status":"healthy","timestamp":"...","config":{...}}');
    } catch (e) {
      debugPrint('❌ Health check error: $e');
    }
  }

  /// Monitor a payment in real-time
  static Stream<String> monitorPaymentDebug(String paymentId) {
    return _firestore
        .collection('payments')
        .doc(paymentId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return 'Payment document not found';
      }

      final data = doc.data()!;
      final status = data['status'] ?? 'unknown';
      final updatedAt = data['updatedAt']?.toDate();
      final processedVia = data['processedVia'] ?? 'not_processed';

      return 'Status: $status | Updated: $updatedAt | Via: $processedVia';
    });
  }

  /// Create a test payment document (for debugging)
  static Future<String> createTestPayment() async {
    try {
      final paymentId = 'TEST_${DateTime.now().millisecondsSinceEpoch}';

      await _firestore.collection('payments').doc(paymentId).set({
        'paymentId': paymentId,
        'userId': 'test_user',
        'amount': 100.0,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'testData': true,
      });

      debugPrint('✅ Created test payment: $paymentId');
      return paymentId;
    } catch (e) {
      debugPrint('❌ Error creating test payment: $e');
      rethrow;
    }
  }

  /// Simulate ITN webhook completion (for testing)
  static Future<void> simulatePaymentCompletion(String paymentId) async {
    try {
      await _firestore.collection('payments').doc(paymentId).update({
        'status': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
        'processedVia': 'manual_simulation',
        'simulatedAt': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Simulated payment completion: $paymentId');
    } catch (e) {
      debugPrint('❌ Error simulating completion: $e');
      rethrow;
    }
  }

  /// Simulate payment cancellation
  static Future<void> simulatePaymentCancellation(String paymentId) async {
    try {
      await _firestore.collection('payments').doc(paymentId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
        'processedVia': 'manual_simulation',
        'cancelledAt': DateTime.now().toIso8601String(),
        'cancellationReason': 'Simulated cancellation for testing',
      });

      debugPrint('🚫 Simulated payment cancellation: $paymentId');
    } catch (e) {
      debugPrint('❌ Error simulating cancellation: $e');
      rethrow;
    }
  }

  /// Get payment errors for debugging
  static Stream<List<Map<String, dynamic>>> getPaymentErrors() {
    return _firestore
        .collection('payment_errors')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  /// Print current payment configuration
  static void printPaymentConfig() {
    debugPrint('🔧 PAYMENT CONFIGURATION:');
    debugPrint('   Merchant ID: 10041473');
    debugPrint('   Sandbox Mode: true');
    debugPrint('   ITN URL: https://payfastitn-5qmz3ymkpa-uc.a.run.app');
    debugPrint('   PayFast URL: https://sandbox.payfast.co.za/eng/process');
  }

  /// Test URL parsing (simulate what happens when user returns from PayFast)
  static void testUrlParsing() {
    final testUrls = [
      'https://yourapp.com/payment/return?payment_status=1&pf_payment_id=12345',
      'https://yourapp.com/payment/cancel?payment_status=2',
      'https://yourapp.com/payment/failure?payment_status=0',
      'https://sandbox.payfast.co.za/eng/process?success=true',
      'https://sandbox.payfast.co.za/eng/process?cancelled=true',
    ];

    for (String url in testUrls) {
      debugPrint('🧪 Testing URL: $url');

      if (url.contains('payment/return') ||
          url.contains('success') ||
          url.contains('payment_status=1')) {
        debugPrint('   ✅ Would trigger success flow');
      } else if (url.contains('payment/cancel') ||
          url.contains('cancelled') ||
          url.contains('payment_status=2')) {
        debugPrint('   🚫 Would trigger cancellation flow');
      } else if (url.contains('payment/failure') ||
          url.contains('failed') ||
          url.contains('payment_status=0')) {
        debugPrint('   ❌ Would trigger failure flow');
      } else {
        debugPrint('   ⚠️ Would continue navigation');
      }
    }
  }
}