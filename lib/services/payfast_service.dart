// lib/services/payfast_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

class PayFastService {
  // PayFast configuration - Replace with your actual credentials
  static const String _merchantId = "10000100"; // Your merchant ID
  static const String _merchantKey = "46f0cd694581a"; // Your merchant key
  static const String _passphrase = "jt7NOE43FZPn"; // Your passphrase (if using)

  // PayFast URLs
  static const String _sandboxUrl = "https://sandbox.payfast.co.za/eng/process";
  static const String _productionUrl = "https://www.payfast.co.za/eng/process";

  // Use sandbox for testing
  static const bool _useSandbox = true;

  static String get paymentUrl => _useSandbox ? _sandboxUrl : _productionUrl;

  /// Generate PayFast payment data
  static Map<String, String> generatePaymentData({
    required String merchantOrderId,
    required double amount,
    required String itemName,
    required String itemDescription,
    required String buyerFirstName,
    required String buyerLastName,
    required String buyerEmail,
    required String returnUrl,
    required String cancelUrl,
    required String notifyUrl,
  }) {
    final data = <String, String>{
      'merchant_id': _merchantId,
      'merchant_key': _merchantKey,
      'return_url': returnUrl,
      'cancel_url': cancelUrl,
      'notify_url': notifyUrl,
      'm_payment_id': merchantOrderId,
      'amount': amount.toStringAsFixed(2),
      'item_name': itemName,
      'item_description': itemDescription,
      'name_first': buyerFirstName,
      'name_last': buyerLastName,
      'email_address': buyerEmail,
    };

    // Generate signature
    final signature = _generateSignature(data);
    data['signature'] = signature;

    return data;
  }

  /// Generate MD5 signature for PayFast
  static String _generateSignature(Map<String, String> data) {
    // Remove signature and hash from data if they exist
    final dataToSign = Map<String, String>.from(data);
    dataToSign.remove('signature');
    dataToSign.remove('hash');

    // Sort parameters alphabetically
    final sortedKeys = dataToSign.keys.toList()..sort();

    // Build parameter string
    final paramString = sortedKeys
        .map((key) => '$key=${Uri.encodeComponent(dataToSign[key]!)}')
        .join('&');

    // Add passphrase if configured
    final stringToSign = _passphrase.isNotEmpty
        ? '$paramString&passphrase=${Uri.encodeComponent(_passphrase)}'
        : paramString;

    if (kDebugMode) {
      print('PayFast signature string: $stringToSign');
    }

    // Generate MD5 hash
    final bytes = utf8.encode(stringToSign);
    final digest = md5.convert(bytes);

    return digest.toString();
  }

  /// Verify PayFast callback signature
  static bool verifyCallback(Map<String, String> postData) {
    if (!postData.containsKey('signature')) {
      return false;
    }

    final receivedSignature = postData['signature']!;
    final calculatedSignature = _generateSignature(postData);

    return receivedSignature == calculatedSignature;
  }

  /// Generate a unique merchant order ID
  static String generateOrderId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999);
    return 'FT_${timestamp}_$random';
  }

  /// Get payment status description
  static String getPaymentStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'complete':
        return 'Payment completed successfully';
      case 'failed':
        return 'Payment failed';
      case 'cancelled':
        return 'Payment was cancelled';
      case 'pending':
        return 'Payment is being processed';
      default:
        return 'Unknown payment status';
    }
  }

  /// Format amount for display
  static String formatAmount(double amount) {
    return 'R ${amount.toStringAsFixed(2)}';
  }

  /// Validate payment amount (PayFast minimum is R5.00)
  static bool isValidAmount(double amount) {
    return amount >= 5.00;
  }

  /// Generate test card details for sandbox
  static Map<String, String> getTestCardDetails() {
    return {
      'card_number': '4000000000000002',
      'expiry_month': '12',
      'expiry_year': '2025',
      'cvv': '123',
      'cardholder_name': 'Test User',
    };
  }
}