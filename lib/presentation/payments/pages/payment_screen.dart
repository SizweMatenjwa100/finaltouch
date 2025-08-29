// lib/presentation/payments/pages/payment_screen.dart - COMPLETE VERSION
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../features/payment/data/payment_repository.dart';
import '../../../features/payment/logic/payment_bloc.dart';
import '../../../features/payment/logic/payment_event.dart';
import '../../../features/payment/logic/payment_state.dart';
import '../../../services/pricing_service.dart';
import '../../../main_navigation.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;

  const PaymentScreen({
    super.key,
    required this.bookingData,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with TickerProviderStateMixin {
  late final PaymentRepository _repo;
  late final PaymentBloc _paymentBloc;
  late PriceBreakdown _priceBreakdown;
  WebViewController? _webViewController;

  String _currentPaymentId = '';
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _statusSub;
  bool _dialogShown = false;
  bool _processingPayment = false;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _repo = PaymentRepository(
      auth: FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
      functions: FirebaseFunctions.instanceFor(region: 'us-central1'),
    );

    _paymentBloc = PaymentBloc(paymentRepository: _repo);
    _priceBreakdown = PricingService.calculatePrice(widget.bookingData);

    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));

    _initializeWebView();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _slideController.forward();
      _initiatePayment();
    });
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (kDebugMode) print("WebView progress: $progress%");
          },
          onPageStarted: (String url) {
            if (kDebugMode) print("Page started: $url");
            _handleNavigationUrl(url);
          },
          onPageFinished: (String url) {
            if (kDebugMode) print("Page finished: $url");
            _handleNavigationUrl(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            if (kDebugMode) print("Navigation: ${request.url}");
            _handleNavigationUrl(request.url);
            return NavigationDecision.navigate;
          },
        ),
      );
  }

  void _handleNavigationUrl(String url) {
    if (_dialogShown || _processingPayment) return;

    if (kDebugMode) print("Analyzing URL: $url");

    // Success detection
    if (url.contains('payment/return') ||
        url.contains('/return') ||
        url.contains('success=true') ||
        url.contains('payment_status=1')) {
      if (kDebugMode) print("Success URL detected");
      _handlePaymentSuccess();
    }

    // Cancellation detection
    else if (url.contains('payment/cancel') ||
        url.contains('/cancel') ||
        url.contains('cancelled=true') ||
        url.contains('payment_status=2')) {
      if (kDebugMode) print("Cancel URL detected");
      _handlePaymentCancellation();
    }

    // Failure detection
    else if (url.contains('payment/failure') ||
        url.contains('/failure') ||
        url.contains('failed=true') ||
        url.contains('payment_status=0')) {
      if (kDebugMode) print("Failure URL detected");
      _handlePaymentFailure("Payment failed");
    }
  }

  void _handlePaymentSuccess() async {
    if (_processingPayment) return;
    _processingPayment = true;

    _showProcessingDialog("Payment successful! Processing...");

    // First, try to wait for ITN webhook
    bool itnProcessed = await _waitForITNProcessing();

    if (!itnProcessed) {
      if (kDebugMode) print("ITN failed, using manual fallback");
      await _processPaymentManually('completed');
    }

    _showPaymentSuccessDialog();
  }

  void _handlePaymentCancellation() {
    if (_processingPayment) return;
    _processingPayment = true;

    _processPaymentManually('cancelled').then((_) {
      _showPaymentCancelledDialog();
    });
  }

  void _handlePaymentFailure(String reason) {
    if (_processingPayment) return;
    _processingPayment = true;

    _processPaymentManually('failed').then((_) {
      _showFailureDialog(reason);
    });
  }

  Future<bool> _waitForITNProcessing() async {
    if (_currentPaymentId.isEmpty) return false;

    // Wait up to 15 seconds for ITN webhook to process
    for (int i = 0; i < 15; i++) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('payments')
            .doc(_currentPaymentId)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          final status = data['status'] as String;
          final processedVia = data['processedVia'] as String?;

          if (status == 'completed' && processedVia == 'itn_webhook') {
            if (kDebugMode) print("ITN processed successfully");
            return true;
          }
        }
      } catch (e) {
        if (kDebugMode) print("Error checking ITN status: $e");
      }

      await Future.delayed(const Duration(seconds: 1));
    }

    return false;
  }

  Future<void> _processPaymentManually(String status) async {
    if (_currentPaymentId.isEmpty) return;

    try {
      final paymentDoc = await FirebaseFirestore.instance
          .collection('payments')
          .doc(_currentPaymentId)
          .get();

      if (!paymentDoc.exists) {
        throw Exception("Payment document not found");
      }

      final paymentData = paymentDoc.data()!;

      // Update payment status
      await FirebaseFirestore.instance
          .collection('payments')
          .doc(_currentPaymentId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        'processedVia': 'manual_fallback',
        if (status == 'completed') 'completedAt': FieldValue.serverTimestamp(),
        if (status == 'cancelled') 'cancelledAt': FieldValue.serverTimestamp(),
        if (status == 'failed') 'failedAt': FieldValue.serverTimestamp(),
      });

      // Create booking only for completed payments
      if (status == 'completed') {
        await _createBookingFromPayment(paymentData);
      }

      if (kDebugMode) print("Payment processed manually: $status");
    } catch (e) {
      if (kDebugMode) print("Error processing payment manually: $e");
      rethrow;
    }
  }

  Future<void> _createBookingFromPayment(Map<String, dynamic> paymentData) async {
    final userId = paymentData['userId'] as String;
    final bookingDataStr = paymentData['bookingData'] as String;
    final bookingData = jsonDecode(bookingDataStr) as Map<String, dynamic>;

    // Get or create location
    final locationsQuery = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('locations')
        .limit(1)
        .get();

    String locationId;
    if (locationsQuery.docs.isEmpty) {
      final locationRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('locations')
          .doc();

      await locationRef.set({
        'lat': -33.918861,
        'lng': 18.4233,
        'address': "Cape Town, South Africa",
        'autoCreated': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      locationId = locationRef.id;
    } else {
      locationId = locationsQuery.docs.first.id;
    }

    // Create booking
    final bookingRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('locations')
        .doc(locationId)
        .collection('bookings')
        .doc();

    final completeBookingData = {
      ...bookingData,
      'id': bookingRef.id,
      'userId': userId,
      'locationId': locationId,
      'paymentId': _currentPaymentId,
      'paymentStatus': 'paid',
      'status': 'confirmed',
      'totalAmount': paymentData['amount'],
      'currency': paymentData['currency'] ?? 'ZAR',
      'createdAt': FieldValue.serverTimestamp(),
      'confirmedAt': FieldValue.serverTimestamp(),
      'paidAt': FieldValue.serverTimestamp(),
    };

    await bookingRef.set(completeBookingData);

    // Create notification
    final notificationRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc();

    await notificationRef.set({
      'type': 'payment_success',
      'title': 'Payment Successful!',
      'message': 'Your booking for ${bookingData['cleaningType'] ?? 'cleaning service'} has been confirmed.',
      'paymentId': _currentPaymentId,
      'bookingId': bookingRef.id,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (kDebugMode) print("Booking created: ${bookingRef.id}");
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _paymentBloc.close();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _initiatePayment() {
    _paymentBloc.add(InitiatePayment(
      bookingData: widget.bookingData,
      amount: _priceBreakdown.total,
      currency: 'ZAR',
    ));
  }

  void _startMonitoringPayment(String paymentId) {
    if (kDebugMode) print("Monitoring payment: $paymentId");

    _statusSub?.cancel();

    _statusSub = FirebaseFirestore.instance
        .collection('payments')
        .doc(paymentId)
        .snapshots()
        .listen((snap) {
      if (!mounted || _dialogShown || _processingPayment) return;

      if (snap.exists) {
        final data = snap.data()!;
        final status = (data['status'] ?? '').toString().toLowerCase();
        final processedVia = data['processedVia'] as String?;

        if (kDebugMode) print("Status update: $status via $processedVia");

        // Only handle ITN webhook updates here
        if (processedVia == 'itn_webhook') {
          if (status == 'completed') {
            _showPaymentSuccessDialog();
          } else if (status == 'failed') {
            _showFailureDialog("Payment processing failed");
          } else if (status == 'cancelled') {
            _showPaymentCancelledDialog();
          }
        }
      }
    });
  }

  void _showProcessingDialog(String message) {
    if (_dialogShown) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1CABE3), Color(0xFF21E065)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1CABE3).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.payments,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                message,
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1CABE3),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Please wait while we confirm your payment...",
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentSuccessDialog() {
    if (_dialogShown) return;
    _dialogShown = true;
    _processingPayment = false;

    _statusSub?.cancel();

    // Close any existing dialog
    if (Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1CABE3), Color(0xFF0EA5E9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1CABE3).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Payment Successful!",
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1CABE3),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Your booking has been confirmed and you'll receive a confirmation email shortly.",
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1CABE3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt, color: const Color(0xFF1CABE3), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Payment ID",
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentPaymentId.substring(0, 12).toUpperCase(),
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1CABE3),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const MainNavigation()),
                          (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1CABE3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "Continue to Home",
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentCancelledDialog() {
    if (_dialogShown) return;
    _dialogShown = true;
    _processingPayment = false;

    _statusSub?.cancel();

    if (Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.orange, width: 2),
                ),
                child: const Icon(
                  Icons.cancel_outlined,
                  color: Colors.orange,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Payment Cancelled",
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Your payment was cancelled. You can try again or choose a different payment method.",
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.orange),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        "Back to Review",
                        style: GoogleFonts.manrope(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _dialogShown = false;
                        _processingPayment = false;
                        _initiatePayment();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1CABE3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: Text(
                        "Try Again",
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFailureDialog(String message) {
    if (_dialogShown) return;
    _dialogShown = true;
    _processingPayment = false;

    _statusSub?.cancel();

    if (Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Payment Failed",
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _dialogShown = false;
                        _processingPayment = false;
                        _initiatePayment();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1CABE3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "Try Again",
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Back to Review",
                        style: GoogleFonts.manrope(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _paymentBloc,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: BlocListener<PaymentBloc, PaymentState>(
            listener: (context, state) {
              if (state is PaymentReady) {
                _currentPaymentId = state.paymentId;
                if (kDebugMode) print("Payment ID stored: $_currentPaymentId");
                _startMonitoringPayment(_currentPaymentId);
              } else if (state is PaymentFailed && !_dialogShown) {
                _showFailureDialog(state.error);
              }
            },
            child: BlocBuilder<PaymentBloc, PaymentState>(
              builder: (context, state) {
                if (state is PaymentInitiating) {
                  return _buildInitializingState();
                } else if (state is PaymentReady) {
                  return _buildPaymentWebView(state.paymentUrl);
                } else if (state is PaymentFailed) {
                  return _buildErrorState(state.error);
                } else {
                  return _buildInitializingState();
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitializingState() {
    return Column(
      children: [
        _buildAppBar(),
        Expanded(
          child: SlideTransition(
            position: _slideAnimation,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1CABE3), Color(0xFF21E065)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1CABE3).withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.credit_card,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Text(
                    "Setting up secure payment",
                    style: GoogleFonts.manrope(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1CABE3),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Preparing your payment gateway...",
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1CABE3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: const Color(0xFF1CABE3).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.security, color: Color(0xFF1CABE3), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "256-bit SSL Encryption",
                          style: GoogleFonts.manrope(
                            color: const Color(0xFF1CABE3),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              _statusSub?.cancel();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back_ios),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Secure Payment",
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  PricingService.formatPrice(_priceBreakdown.total),
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1CABE3),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1CABE3).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock,
              color: Color(0xFF1CABE3),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentWebView(String paymentUrl) {
    if (_webViewController != null) {
      _webViewController!.loadRequest(Uri.parse(paymentUrl));
    }

    return Column(
      children: [
        _buildAppBar(),
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1CABE3).withOpacity(0.1),
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1CABE3).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1CABE3), Color(0xFF21E065)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.security, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "PayFast Secure Gateway",
                      style: GoogleFonts.manrope(
                        color: const Color(0xFF1CABE3),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "Complete your payment below",
                      style: GoogleFonts.manrope(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => _openPaymentInBrowser(paymentUrl),
                icon: const Icon(Icons.open_in_browser, size: 18),
                label: Text(
                  "Browser",
                  style: GoogleFonts.manrope(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1CABE3),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _webViewController != null
                  ? WebViewWidget(controller: _webViewController!)
                  : const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF1CABE3),
                ),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.security, size: 16, color: Color(0xFF1CABE3)),
                  const SizedBox(width: 8),
                  Text(
                    "Your payment is secured by PayFast",
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: const Color(0xFF1CABE3),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    _statusSub?.cancel();
                    if (_currentPaymentId.isNotEmpty) {
                      await _processPaymentManually('cancelled');
                    }
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close, size: 20),
                  label: Text(
                    "Cancel Payment",
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Column(
      children: [
        _buildAppBar(),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.red.withOpacity(0.3), width: 2),
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      size: 50,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    "Payment Setup Failed",
                    style: GoogleFonts.manrope(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _dialogShown = false;
                            _processingPayment = false;
                            _initiatePayment();
                          },
                          icon: const Icon(Icons.refresh),
                          label: Text(
                            "Try Again",
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1CABE3),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade400),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Back to Review",
                            style: GoogleFonts.manrope(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openPaymentInBrowser(String paymentUrl) async {
    final uri = Uri.parse(paymentUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Could not open payment page"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}