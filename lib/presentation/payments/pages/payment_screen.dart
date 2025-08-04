// lib/presentation/payment/pages/payment_screen.dart - FINAL FIXED VERSION
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../features/payment/data/payment_repository.dart';
import '../../../features/payment/logic/payment_bloc.dart';
import '../../../features/payment/logic/payment_event.dart';
import '../../../features/payment/logic/payment_state.dart';
import '../../../services/pricing_service.dart';

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
  late PaymentBloc _paymentBloc;
  late PriceBreakdown _priceBreakdown;
  WebViewController? _webViewController;
  String _currentPaymentId = ''; // Store the current payment ID

  @override
  void initState() {
    super.initState();
    _paymentBloc = PaymentBloc(
      paymentRepository: PaymentRepository(
        auth: FirebaseAuth.instance,
        firestore: FirebaseFirestore.instance,
      ),
    );
    _priceBreakdown = PricingService.calculatePrice(widget.bookingData);
    _initializeWebView();

    // Automatically initiate payment when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initiatePayment();
    });
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            print("🌐 WebView loading progress: $progress%");
          },
          onPageStarted: (String url) {
            print("🌐 Payment page started loading: $url");
          },
          onPageFinished: (String url) {
            print("🌐 Payment page finished loading: $url");
          },
          onNavigationRequest: (NavigationRequest request) {
            print("🌐 Navigation request: ${request.url}");
            // Use the stored payment ID
            _handlePaymentCallback(request.url, _currentPaymentId);
            return NavigationDecision.navigate;
          },
        ),
      );
  }

  @override
  void dispose() {
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

  void _showPaymentSuccessDialog(String bookingId) {
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
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Payment Successful!",
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Your booking has been confirmed and you'll receive a confirmation email shortly.",
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Booking ID: ${bookingId.substring(0, 8).toUpperCase()}",
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1CABE3),
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.popUntil(context, (route) => route.isFirst); // Go to home
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1CABE3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                "Continue",
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
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
          title: Text(
            "Secure Payment",
            style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: BlocListener<PaymentBloc, PaymentState>(
          listener: (context, state) {
            // Store the payment ID when it's ready
            if (state is PaymentReady) {
              _currentPaymentId = state.paymentId;
              print("💾 Stored payment ID: $_currentPaymentId");
            } else if (state is PaymentSuccess) {
              _showPaymentSuccessDialog(state.bookingId);
            } else if (state is PaymentFailed) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(child: Text(state.error)),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
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
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          // Security indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.security,
                size: 16,
                color: Colors.green,
              ),
              const SizedBox(width: 4),
              Text(
                "Secured by PayFast",
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentWebView(String paymentUrl, String paymentId) {
    // Load the payment URL
    if (_webViewController != null) {
      _webViewController!.loadRequest(Uri.parse(paymentUrl));
    }

    return Column(
      children: [
        // Payment header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1CABE3).withOpacity(0.1),
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.security,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Secure Payment Gateway",
                      style: GoogleFonts.manrope(
                        color: const Color(0xFF1CABE3),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      "Amount: ${PricingService.formatPrice(_priceBreakdown.total)}",
                      style: GoogleFonts.manrope(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
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
        ),

        // WebView
        Expanded(
          child: _webViewController != null
              ? WebViewWidget(controller: _webViewController!)
              : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  color: Color(0xFF1CABE3),
                ),
                const SizedBox(height: 16),
                Text(
                  "Loading payment page...",
                  style: GoogleFonts.manrope(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom actions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _paymentBloc.add(ProcessPaymentFailure(
                        paymentId: paymentId,
                        error: "Payment cancelled by user",
                      ));
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      "Cancel Payment",
                      style: GoogleFonts.manrope(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _simulatePaymentSuccess(paymentId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      "Test Success",
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
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
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
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
              state.error,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),

            // Action buttons
            Column(
              children: [
                if (state.canRetry)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _paymentBloc.add(RetryPayment(
                          bookingData: widget.bookingData,
                          amount: _priceBreakdown.total,
                        ));
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        "Try Again",
                        style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1CABE3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Back to Review",
                      style: GoogleFonts.manrope(
                        color: Colors.grey.shade700,
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
    );
  }

  void _openPaymentInBrowser(String paymentUrl) async {
    final uri = Uri.parse(paymentUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open payment page")),
      );
    }
  }

  void _simulatePaymentSuccess(String paymentId) {
    // This is for testing purposes only - remove in production
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Test Payment",
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "This will simulate a successful payment for testing purposes.",
          style: GoogleFonts.manrope(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.manrope(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _paymentBloc.add(ProcessPaymentSuccess(
                paymentId: paymentId,
                paymentToken: "test_token_${DateTime.now().millisecondsSinceEpoch}",
                paymentDetails: {
                  'test': true,
                  'timestamp': DateTime.now().toIso8601String(),
                },
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: Text(
              "Confirm Test Payment",
              style: GoogleFonts.manrope(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _handlePaymentCallback(String url, String paymentId) {
    print("🌐 Handling payment callback: $url with paymentId: $paymentId");

    // Ensure we have a valid paymentId
    if (paymentId.isEmpty) {
      print("⚠️ PaymentId is empty, cannot process callback");
      return;
    }

    // Handle PayFast callback URLs
    if (url.contains('payment_status=1') ||
        url.contains('/payment/success') ||
        url.contains('success')) {

      // Extract payment details from URL if needed
      final uri = Uri.parse(url);
      final paymentToken = uri.queryParameters['pf_payment_id'] ??
          uri.queryParameters['payment_id'] ??
          'token_${DateTime.now().millisecondsSinceEpoch}';

      print("✅ Payment successful, processing with paymentId: $paymentId");

      _paymentBloc.add(ProcessPaymentSuccess(
        paymentId: paymentId,
        paymentToken: paymentToken,
        paymentDetails: {
          'returnUrl': url,
          'timestamp': DateTime.now().toIso8601String(),
          'queryParams': uri.queryParameters,
        },
      ));
    } else if (url.contains('payment_status=2') ||
        url.contains('/payment/cancel') ||
        url.contains('cancel')) {

      _paymentBloc.add(ProcessPaymentFailure(
        paymentId: paymentId,
        error: "Payment was cancelled by user",
      ));
    } else if (url.contains('payment_status=0') ||
        url.contains('/payment/failure') ||
        url.contains('failed')) {

      _paymentBloc.add(ProcessPaymentFailure(
        paymentId: paymentId,
        error: "Payment failed. Please try again.",
      ));
    }
  }
}