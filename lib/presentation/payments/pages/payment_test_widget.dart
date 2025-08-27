// lib/widgets/payment_test_widget.dart - ADD THIS FOR TESTING
import 'dart:convert';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class PaymentTestWidget extends StatefulWidget {
  const PaymentTestWidget({super.key});

  @override
  State<PaymentTestWidget> createState() => _PaymentTestWidgetState();
}

class _PaymentTestWidgetState extends State<PaymentTestWidget> {
  String _testResults = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "🧪 Payment Testing",
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Test payment functionality (Development Only)",
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTestButton("Health Check", _testHealthCheck, Colors.blue),
              _buildTestButton("Create Test Payment", _createTestPayment, Colors.green),
              _buildTestButton("Simulate Success", _simulateSuccess, Colors.green),
              _buildTestButton("Simulate Cancel", _simulateCancel, Colors.orange),
              _buildTestButton("Check Errors", _checkErrors, Colors.red),
            ],
          ),

          if (_testResults.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Test Results:",
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _testResults,
                    style: GoogleFonts.manrope(
                      fontSize: 10,

                    ),
                  ),
                ],
              ),
            ),
          ],

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTestButton(String label, VoidCallback onPressed, Color color) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _testHealthCheck() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Testing Cloud Function health...';
    });

    try {
      final response = await http.get(
        Uri.parse('https://payfastitn-5qmz3ymkpa-uc.a.run.app/payfastHealthCheck'),
        headers: {'Content-Type': 'application/json'},
      );

      setState(() {
        _testResults = 'Health Check Response:\n'
            'Status: ${response.statusCode}\n'
            'Body: ${response.body}';
      });
    } catch (e) {
      setState(() {
        _testResults = 'Health Check Error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createTestPayment() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Creating test payment...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _testResults = 'Error: No authenticated user';
        });
        return;
      }

      final paymentId = 'TEST_${DateTime.now().millisecondsSinceEpoch}';
      final testBookingData = {
        'cleaningType': 'Standard Cleaning',
        'propertyType': 'Apartment',
        'bedrooms': 2,
        'bathrooms': 1,
        'selectedDate': DateTime.now().toIso8601String(),
        'selectedTime': '10:00',
      };

      await FirebaseFirestore.instance.collection('payments').doc(paymentId).set({
        'paymentId': paymentId,
        'userId': user.uid,
        'userEmail': user.email ?? '',
        'bookingData': jsonEncode(testBookingData),
        'amount': 150.0,
        'currency': 'ZAR',
        'status': 'pending',
        'paymentMethod': 'payfast_test',
        'createdAt': FieldValue.serverTimestamp(),
        'testPayment': true,
      });

      setState(() {
        _testResults = 'Test payment created successfully!\n'
            'Payment ID: $paymentId\n'
            'User: ${user.email}\n'
            'Amount: R150.00\n'
            'Status: pending';
      });
    } catch (e) {
      setState(() {
        _testResults = 'Error creating test payment: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _simulateSuccess() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Finding test payment to simulate success...';
    });

    try {
      // Find the most recent test payment
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _testResults = 'Error: No authenticated user';
        });
        return;
      }

      final paymentsQuery = await FirebaseFirestore.instance
          .collection('payments')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (paymentsQuery.docs.isEmpty) {
        setState(() {
          _testResults = 'No pending payments found. Create a test payment first.';
        });
        return;
      }

      final paymentId = paymentsQuery.docs.first.id;

      // Call the simulate ITN endpoint
      final response = await http.get(
        Uri.parse('https://payfastitn-5qmz3ymkpa-uc.a.run.app/simulateITN?paymentId=$paymentId&status=COMPLETE'),
      );

      setState(() {
        _testResults = 'Simulate Success Response:\n'
            'Payment ID: $paymentId\n'
            'Status: ${response.statusCode}\n'
            'Response: ${response.body}\n'
            '\nCheck Firestore for status change!';
      });
    } catch (e) {
      setState(() {
        _testResults = 'Error simulating success: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _simulateCancel() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Finding test payment to simulate cancellation...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _testResults = 'Error: No authenticated user';
        });
        return;
      }

      final paymentsQuery = await FirebaseFirestore.instance
          .collection('payments')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (paymentsQuery.docs.isEmpty) {
        setState(() {
          _testResults = 'No pending payments found. Create a test payment first.';
        });
        return;
      }

      final paymentId = paymentsQuery.docs.first.id;

      // Simulate cancelled status directly in Firestore
      await FirebaseFirestore.instance
          .collection('payments')
          .doc(paymentId)
          .update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
        'processedVia': 'manual_simulation',
        'cancelledAt': DateTime.now().toIso8601String(),
        'cancellationReason': 'Simulated cancellation for testing',
      });

      setState(() {
        _testResults = 'Payment cancelled successfully!\n'
            'Payment ID: $paymentId\n'
            'New Status: cancelled\n'
            '\nCheck your payment screen for updates!';
      });
    } catch (e) {
      setState(() {
        _testResults = 'Error simulating cancellation: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkErrors() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Checking payment errors...';
    });

    try {
      final errorsQuery = await FirebaseFirestore.instance
          .collection('payment_errors')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();

      if (errorsQuery.docs.isEmpty) {
        setState(() {
          _testResults = 'No payment errors found. Great! 🎉';
        });
        return;
      }

      final errors = errorsQuery.docs.map((doc) {
        final data = doc.data();
        final timestamp = data['timestamp']?.toDate();
        return '${timestamp?.toString() ?? 'Unknown time'}: ${data['type']} - ${data['data']?['error'] ?? 'Unknown error'}';
      }).join('\n\n');

      setState(() {
        _testResults = 'Recent Payment Errors:\n\n$errors';
      });
    } catch (e) {
      setState(() {
        _testResults = 'Error checking errors: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

// Extension method to add jsonEncode


extension PaymentTestHelpers on _PaymentTestWidgetState {
  String jsonEncode(Map<String, dynamic> object) {
    return json.encode(object);
  }
}