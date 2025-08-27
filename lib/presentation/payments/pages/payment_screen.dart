// lib/presentation/payments/pages/payment_screen.dart - WITH DEBUG HELPER
import 'dart:async';
import 'package:flutter/foundation.dart'; // Add this import
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
import '../../../utils/payment_debug_helper.dart'; // Add this import

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;

  const PaymentScreen({
    super.key,
    required this.bookingData,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final PaymentRepository _repo;
  late final PaymentBloc _paymentBloc;
  late PriceBreakdown _priceBreakdown;
  WebViewController? _webViewController;

  String _currentPaymentId = '';
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _statusSub;
  StreamSubscription<String>? _debugSub; // Add debug subscription
  bool _dialogShown = false;

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
    _initializeWebView();

    // ADD DEBUG HELPERS - Only in debug mode
    if (kDebugMode) {
      _initializeDebugHelpers();
    }

    // Kick off payment creation after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _initiatePayment());
  }

  // ADD THIS METHOD
  void _initializeDebugHelpers() {
    print("🔧 Initializing debug helpers...");

    // Print payment configuration
    PaymentDebugHelper.printPaymentConfig();

    // Test URL parsing
    PaymentDebugHelper.testUrlParsing();

    // Test Cloud Function health
    PaymentDebugHelper.testCloudFunctionHealth();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (kDebugMode) print("🌐 WebView loading progress: $progress%");
          },
          onPageStarted: (String url) {
            if (kDebugMode) print("🌐 Payment page started loading: $url");
            _handleNavigationUrl(url);
          },
          onPageFinished: (String url) {
            if (kDebugMode) print("🌐 Payment page finished loading: $url");
            _handleNavigationUrl(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            if (kDebugMode) print("🌐 Navigation request: ${request.url}");
            _handleNavigationUrl(request.url);
            return NavigationDecision.navigate;
          },
        ),
      );
  }

  // Enhanced navigation URL handling with debug info
  void _handleNavigationUrl(String url) {
    if (_dialogShown) return;

    if (kDebugMode) print("🔍 Analyzing URL: $url");

    // FIXED: Only check return/success URLs, not the initial process URL
    if (url.contains('payment/return') ||
        url.contains('/return') ||
        url.contains('success=true') ||
        url.contains('payment_status=1')) {
      if (kDebugMode) print("✅ Detected successful payment URL");
      _showLoadingAndWaitForITN("Payment successful! Confirming...");
    }

    // FIXED: Only check cancel URLs, not process URLs
    else if (url.contains('payment/cancel') ||
        url.contains('/cancel') ||
        url.contains('cancelled=true') ||
        url.contains('payment_status=2')) {
      if (kDebugMode) print("🚫 Detected cancelled payment URL");
      _showPaymentCancelledDialog();
    }

    // FIXED: Only check failure URLs
    else if (url.contains('payment/failure') ||
        url.contains('/failure') ||
        url.contains('failed=true') ||
        url.contains('payment_status=0')) {
      if (kDebugMode) print("❌ Detected failed payment URL");
      _showFailureSnack("Payment failed. Please try again.");
    }

    // DON'T trigger anything for the initial process URL
    else if (url.contains('sandbox.payfast.co.za/eng/process')) {
      if (kDebugMode) print("📄 PayFast process page loaded normally");
      // Do nothing - this is just the payment form loading
    }
  }
  void _showLoadingAndWaitForITN(String message) {
    if (_dialogShown) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF1CABE3)),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Please wait while we confirm your payment...",
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            // ADD DEBUG INFO IN DEBUG MODE
            if (kDebugMode && _currentPaymentId.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "Debug: Monitoring $_currentPaymentId",
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    color: Colors.blue,

                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    // Set a timeout for ITN processing
    Timer(const Duration(seconds: 30), () {
      if (mounted && !_dialogShown) {
        Navigator.of(context, rootNavigator: true).pop();
        _checkPaymentStatusManually();
      }
    });
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _debugSub?.cancel(); // Cancel debug subscription
    _paymentBloc.close();
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
    if (kDebugMode) print("👀 Starting to monitor payment: $paymentId");

    _statusSub?.cancel();
    _debugSub?.cancel();

    // Regular status monitoring
    _statusSub = FirebaseFirestore.instance
        .collection('payments')
        .doc(paymentId)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;

      if (!snap.exists) {
        if (kDebugMode) print("⚠️ Payment document not found: $paymentId");
        return;
      }

      final data = snap.data()!;
      final status = (data['status'] ?? '').toString().toLowerCase();
      final timestamp = data['updatedAt']?.toDate() ?? DateTime.now();

      if (kDebugMode) {
        print("📊 Payment $paymentId status: $status at ${timestamp.toIso8601String()}");
      }

      // Only process if not already shown a dialog
      if (!_dialogShown) {
        if (status == 'completed') {
          if (kDebugMode) print("🎉 Payment completed - showing success dialog");
          _showPaymentSuccessDialog(paymentId, data);
        } else if (status == 'failed') {
          if (kDebugMode) print("💥 Payment failed");
          _showFailureSnack("Payment failed. Please try again.");
        } else if (status == 'cancelled') {
          if (kDebugMode) print("🚫 Payment cancelled");
          _showPaymentCancelledDialog();
        }
      }
    }, onError: (error) {
      if (kDebugMode) print("❌ Error monitoring payment: $error");
      if (!_dialogShown) {
        _showFailureSnack("Error monitoring payment status");
      }
    });

    // ADD DEBUG MONITORING - Only in debug mode
    if (kDebugMode) {
      _debugSub = PaymentDebugHelper.monitorPaymentDebug(paymentId).listen((status) {
        print("🐛 Debug Monitor: $status");
      });
    }
  }

  void _checkPaymentStatusManually() async {
    if (_currentPaymentId.isEmpty) return;

    if (kDebugMode) print("🔍 Manually checking payment status for: $_currentPaymentId");

    try {
      final result = await _repo.verifyPayment(_currentPaymentId);

      if (result.verified) {
        final paymentDoc = await FirebaseFirestore.instance
            .collection('payments')
            .doc(_currentPaymentId)
            .get();

        if (paymentDoc.exists) {
          _showPaymentSuccessDialog(_currentPaymentId, paymentDoc.data()!);
        } else {
          _showPaymentSuccessDialog(_currentPaymentId, {});
        }
      } else {
        _showFailureSnack("Payment verification failed. Please contact support.");
      }
    } catch (e) {
      if (kDebugMode) print("❌ Manual payment check failed: $e");
      _showFailureSnack("Unable to verify payment status");
    }
  }

  void _showPaymentSuccessDialog(String paymentId, Map<String, dynamic> paymentData) {
    if (_dialogShown) return;
    _dialogShown = true;

    // Stop monitoring and close any existing dialogs
    _statusSub?.cancel();
    _debugSub?.cancel();

    // Close loading dialog if open
    if (Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    // Extract booking ID if available
    String bookingId = paymentId;
    if (paymentData.containsKey('bookingId')) {
      bookingId = paymentData['bookingId'];
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              "Payment Successful!",
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Your booking has been confirmed and you'll receive a confirmation email shortly.",
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    "Payment ID",
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    paymentId.substring(0, 8).toUpperCase(),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 16,
                    ),
                  ),
                  // ADD DEBUG INFO
                  if (kDebugMode) ...[
                    const SizedBox(height: 4),
                    Text(
                      "Full ID: $paymentId",
                      style: GoogleFonts.manrope(
                        fontSize: 8,
                        color: Colors.grey,

                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to Home
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const MainNavigation()),
                      (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                "Go to Home",
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
    );
  }

  void _showPaymentCancelledDialog() {
    if (_dialogShown) return;
    _dialogShown = true;

    _statusSub?.cancel();
    _debugSub?.cancel();

    // Close loading dialog if open
    if (Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cancel_outlined, color: Colors.orange, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              "Payment Cancelled",
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Your payment was cancelled. You can try again or choose a different payment method.",
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to review screen
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    _dialogShown = false; // Reset flag
                    _initiatePayment(); // Retry payment
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1CABE3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
    );
  }

  void _showFailureSnack(String message) {
    if (_dialogShown) return;

    _statusSub?.cancel();
    _debugSub?.cancel();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () {
            _dialogShown = false; // Reset flag
            _initiatePayment();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _paymentBloc,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text("Secure Payment", style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _statusSub?.cancel();
              _debugSub?.cancel();
              Navigator.pop(context);
            },
          ),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: BlocListener<PaymentBloc, PaymentState>(
          listener: (context, state) {
            if (state is PaymentReady) {
              _currentPaymentId = state.paymentId;
              if (kDebugMode) print("💾 Stored payment ID: $_currentPaymentId");
              _startMonitoringPayment(_currentPaymentId);
            } else if (state is PaymentFailed) {
              _showFailureSnack(state.error);
            }
          },
          child: BlocBuilder<PaymentBloc, PaymentState>(
            builder: (context, state) {
              if (state is PaymentInitiating) {
                return _buildLoadingContent("Setting up secure payment...");
              } else if (state is PaymentReady) {
                return _buildPaymentWebView(state.paymentUrl, state.paymentId);
              } else if (state is PaymentProcessing) {
                return _buildLoadingContent("Processing your payment...");
              } else if (state is PaymentFailed) {
                return _buildErrorContent(state);
              } else {
                return _buildLoadingContent("Initializing payment...");
              }
            },
          ),
        ),
      ),
    );
  }

  // Rest of your existing build methods remain the same...
  Widget _buildLoadingContent(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1CABE3).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: Color(0xFF1CABE3),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1CABE3),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Please wait...",
            style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security, size: 16, color: Colors.green),
              const SizedBox(width: 4),
              Text(
                "Secured by PayFast",
                style: GoogleFonts.manrope(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentWebView(String paymentUrl, String paymentId) {
    if (_webViewController != null) {
      _webViewController!.loadRequest(Uri.parse(paymentUrl));
    }

    return Column(
      children: [
        // Payment header with status indicator
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF1CABE3).withOpacity(0.1), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.security, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Secure Payment Gateway",
                          style: GoogleFonts.manrope(
                            color: const Color(0xFF1CABE3),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text("Amount: ${PricingService.formatPrice(_priceBreakdown.total)}",
                          style: GoogleFonts.manrope(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _openPaymentInBrowser(paymentUrl),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: Text(
                      "Open in Browser",
                      style: GoogleFonts.manrope(
                        color: const Color(0xFF1CABE3),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Monitoring payment status: $paymentId",
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    color: const Color(0xFF1CABE3),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // WebView
        Expanded(
          child: _webViewController != null
              ? WebViewWidget(controller: _webViewController!)
              : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Color(0xFF1CABE3)),
                const SizedBox(height: 16),
                Text("Loading payment page...", style: GoogleFonts.manrope(color: Colors.grey.shade600)),
              ],
            ),
          ),
        ),

        // Bottom actions with debug button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(color: Colors.white, boxShadow: [
            BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, -2)),
          ]),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      _statusSub?.cancel();
                      _debugSub?.cancel();
                      // Optional: mark as cancelled server-side
                      if (_currentPaymentId.isNotEmpty) {
                        await _repo.cancelPayment(_currentPaymentId, "Payment cancelled by user");
                      }
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      "Cancel Payment",
                      style: GoogleFonts.manrope(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _checkPaymentStatusManually(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1CABE3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      "Check Status",
                      style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorContent(PaymentFailed state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.error_outline, size: 64, color: Colors.red),
            ),
            const SizedBox(height: 24),
            Text("Payment Failed",
                style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 12),
            Text(state.error, textAlign: TextAlign.center,
                style: GoogleFonts.manrope(fontSize: 16, color: Colors.grey.shade600)),
            const SizedBox(height: 32),
            Column(
              children: [
                if (state.canRetry)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _dialogShown = false; // Reset dialog flag
                        _paymentBloc.add(RetryPayment(
                          bookingData: widget.bookingData,
                          amount: _priceBreakdown.total,
                        ));
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text("Try Again", style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1CABE3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                if (state.canRetry) const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade400),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text("Back to Review",
                        style: GoogleFonts.manrope(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openPaymentInBrowser(String paymentUrl) async {
    final uri = Uri.parse(paymentUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Could not open payment page")));
    }
  }
}