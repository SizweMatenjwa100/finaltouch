// lib/presentation/payment/pages/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../features/payment/logic/payment_bloc.dart';
import '../../../features/payment/logic/payment_event.dart';
import '../../../features/payment/logic/payment_state.dart';
import '../../../services/pricing_service.dart';

class PaymentScreen extends StatefulWidget {
  final String bookingId;
  final String locationId;
  final Map<String, dynamic> bookingData;

  const PaymentScreen({
    super.key,
    required this.bookingId,
    required this.locationId,
    required this.bookingData,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late WebViewController _webViewController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
            _handleUrlChange(url);
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            _handleUrlChange(request.url);
            return NavigationDecision.navigate;
          },
        ),
      );
  }

  void _handleUrlChange(String url) {
    print("🌐 Navigation to: $url");

    // Handle payment success
    if (url.contains('/payment/success')) {
      _handlePaymentSuccess(url);
    }
    // Handle payment cancellation
    else if (url.contains('/payment/cancel')) {
      _handlePaymentCancel();
    }
    // Handle payment notification (webhook simulation)
    else if (url.contains('/payment/notify')) {
      _handlePaymentNotification(url);
    }
  }

  void _handlePaymentSuccess(String url) {
    final uri = Uri.parse(url);
    final merchantOrderId = uri.queryParameters['m_payment_id'];

    if (merchantOrderId != null) {
      context.read<PaymentBloc>().add(
        ProcessPaymentCallback(
          merchantOrderId: merchantOrderId,
          paymentStatus: 'complete',
          callbackData: uri.queryParameters,
        ),
      );
    }
  }

  void _handlePaymentCancel() {
    context.read<PaymentBloc>().add(
      ProcessPaymentCallback(
        merchantOrderId: 'cancelled',
        paymentStatus: 'cancelled',
        callbackData: {'status': 'cancelled'},
      ),
    );
  }

  void _handlePaymentNotification(String url) {
    // In a real app, this would be handled by your backend
    final uri = Uri.parse(url);
    final merchantOrderId = uri.queryParameters['m_payment_id'];

    if (merchantOrderId != null) {
      context.read<PaymentBloc>().add(
        ProcessPaymentCallback(
          merchantOrderId: merchantOrderId,
          paymentStatus: 'complete',
          callbackData: uri.queryParameters,
        ),
      );
    }
  }

  void _initiatePayment() {
    final priceBreakdown = PricingService.calculatePrice(widget.bookingData);

    context.read<PaymentBloc>().add(
      InitiatePayment(
        bookingId: widget.bookingId,
        locationId: widget.locationId,
        amount: priceBreakdown.total,
        itemName: "Final Touch Cleaning Service",
        itemDescription: "${widget.bookingData['cleaningType']} - ${widget.bookingData['propertyType']}",
        bookingData: widget.bookingData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Secure Payment",
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.security, color: Color(0xFF1CABE3)),
            onPressed: () => _showSecurityInfo(),
          ),
        ],
      ),
      body: BlocListener<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentSuccess) {
            _showPaymentSuccessDialog();
          } else if (state is PaymentFailed) {
            _showPaymentErrorDialog(state.error);
          } else if (state is PaymentCancelled) {
            _showPaymentCancelledDialog();
          }
        },
        child: BlocBuilder<PaymentBloc, PaymentState>(
          builder: (context, state) {
            if (state is PaymentInitial) {
              return _buildInitialView();
            } else if (state is PaymentLoading) {
              return _buildLoadingView();
            } else if (state is PaymentInitiated) {
              return _buildWebView(state);
            } else if (state is PaymentPending) {
              return _buildPendingView(state);
            } else {
              return _buildErrorView("Something went wrong");
            }
          },
        ),
      ),
    );
  }

  Widget _buildInitialView() {
    final priceBreakdown = PricingService.calculatePrice(widget.bookingData);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Booking summary
          _buildBookingSummary(),

          const SizedBox(height: 32),

          // Payment summary
          _buildPaymentSummary(priceBreakdown),

          const SizedBox(height: 32),

          // Payment methods info
          _buildPaymentMethodsInfo(),

          const SizedBox(height: 32),

          // Security notice
          _buildSecurityNotice(),

          const SizedBox(height: 48),

          // Pay now button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _initiatePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1CABE3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payment, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    "Pay ${PricingService.formatPrice(priceBreakdown.total)}",
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF1CABE3)),
          SizedBox(height: 16),
          Text("Preparing secure payment..."),
        ],
      ),
    );
  }

  Widget _buildWebView(PaymentInitiated state) {
    // Load the PayFast payment form directly
    final htmlContent = _generatePayFastForm(state.paymentUrl, state.paymentData);

    _webViewController.loadHtmlString(htmlContent);

    return Stack(
      children: [
        WebViewWidget(controller: _webViewController),
        if (_isLoading)
          Container(
            color: Colors.white,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF1CABE3)),
                  SizedBox(height: 16),
                  Text("Loading secure payment gateway..."),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPendingView(PaymentPending state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.hourglass_empty,
                size: 48,
                color: Colors.orange.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Payment Processing",
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<PaymentBloc>().add(
                  CheckPaymentStatus(merchantOrderId: state.merchantOrderId),
                );
              },
              child: Text("Check Status"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              "Payment Error",
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Go Back"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingSummary() {
    final priceBreakdown = PricingService.calculatePrice(widget.bookingData);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1CABE3).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1CABE3).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cleaning_services, color: Color(0xFF1CABE3)),
              const SizedBox(width: 8),
              Text(
                "Booking Summary",
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1CABE3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow("Service", widget.bookingData['cleaningType'] ?? 'Standard Cleaning'),
          _buildSummaryRow("Property", _buildPropertyString()),
          _buildSummaryRow("Date", _formatBookingDate()),
          _buildSummaryRow("Time", widget.bookingData['selectedTime'] ?? 'Not set'),
        ],
      ),
    );
  }

  String _buildPropertyString() {
    final propertyType = widget.bookingData['propertyType'] ?? 'Property';
    final bedrooms = widget.bookingData['bedrooms'] ?? 1;
    final bathrooms = widget.bookingData['bathrooms'] ?? 1;
    return "$propertyType • $bedrooms bed • $bathrooms bath";
  }

  Widget _buildPaymentSummary(PriceBreakdown breakdown) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Payment Summary",
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPriceRow("Base Price", PricingService.formatPrice(breakdown.basePrice)),
          if (breakdown.roomsPrice > 0)
            _buildPriceRow("Additional Rooms", PricingService.formatPrice(breakdown.roomsPrice)),
          if (breakdown.addOnsPrice > 0)
            _buildPriceRow("Add-ons", PricingService.formatPrice(breakdown.addOnsPrice)),
          if (breakdown.sameCleanerFee > 0)
            _buildPriceRow("Same Cleaner", PricingService.formatPrice(breakdown.sameCleanerFee)),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Amount",
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                PricingService.formatPrice(breakdown.total),
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1CABE3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Accepted Payment Methods",
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildPaymentMethodIcon("assets/images/visa_logo.png"),
              const SizedBox(width: 12),
              _buildPaymentMethodIcon("assets/images/mastercard_logo.png"),
              const SizedBox(width: 12),
              _buildPaymentMethodIcon("assets/images/payfast_logo.png"),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Secure payments powered by PayFast",
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.security, color: Colors.green.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Secure Payment",
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                Text(
                  "Your payment is protected by 256-bit SSL encryption",
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(fontSize: 14),
          ),
          Text(
            price,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodIcon(String assetPath) {
    return Container(
      height: 32,
      width: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Image.asset(
          assetPath,
          height: 20,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.credit_card, size: 20, color: Colors.grey.shade400);
          },
        ),
      ),
    );
  }

  String _formatBookingDate() {
    final dateString = widget.bookingData['selectedDate'] as String?;
    if (dateString == null) return 'Not set';

    try {
      final date = DateTime.parse(dateString);
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return "${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}";
    } catch (e) {
      return dateString;
    }
  }

  String _generatePayFastForm(String actionUrl, Map<String, String> formData) {
    final formFields = formData.entries
        .map((entry) => '<input type="hidden" name="${entry.key}" value="${entry.value}">')
        .join('\n');

    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Secure Payment</title>
        <style>
            body {
                font-family: 'Arial', sans-serif;
                background: linear-gradient(135deg, #1CABE3 0%, #0EA5E9 100%);
                margin: 0;
                padding: 20px;
                min-height: 100vh;
                display: flex;
                align-items: center;
                justify-content: center;
            }
            .container {
                background: white;
                border-radius: 12px;
                padding: 32px;
                box-shadow: 0 10px 25px rgba(0,0,0,0.1);
                text-align: center;
                max-width: 400px;
                width: 100%;
            }
            .logo {
                width: 60px;
                height: 60px;
                background: #1CABE3;
                border-radius: 50%;
                margin: 0 auto 24px;
                display: flex;
                align-items: center;
                justify-content: center;
                color: white;
                font-size: 24px;
            }
            h1 {
                color: #333;
                margin-bottom: 16px;
                font-size: 24px;
            }
            p {
                color: #666;
                margin-bottom: 32px;
            }
            .btn {
                background: #1CABE3;
                color: white;
                border: none;
                padding: 16px 32px;
                border-radius: 8px;
                font-size: 16px;
                font-weight: bold;
                cursor: pointer;
                width: 100%;
                transition: background 0.3s;
            }
            .btn:hover {
                background: #0EA5E9;
            }
            .spinner {
                border: 3px solid #f3f3f3;
                border-top: 3px solid #1CABE3;
                border-radius: 50%;
                width: 24px;
                height: 24px;
                animation: spin 1s linear infinite;
                margin: 16px auto;
                display: none;
            }
            @keyframes spin {
                0% { transform: rotate(0deg); }
                100% { transform: rotate(360deg); }
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="logo">🔒</div>
            <h1>Secure Payment</h1>
            <p>You will be redirected to PayFast to complete your payment securely.</p>
            
            <form id="payfast_form" action="$actionUrl" method="post">
                $formFields
                <button type="submit" class="btn" onclick="showSpinner()">
                    Continue to Payment
                </button>
            </form>
            
            <div class="spinner" id="spinner"></div>
        </div>
        
        <script>
            function showSpinner() {
                document.querySelector('.btn').style.display = 'none';
                document.getElementById('spinner').style.display = 'block';
            }
            
            // Auto-submit after 2 seconds
            setTimeout(function() {
                showSpinner();
                document.getElementById('payfast_form').submit();
            }, 2000);
        </script>
    </body>
    </html>
    ''';
  }

  void _showPaymentSuccessDialog() {
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
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Your booking has been confirmed. You'll receive a confirmation email shortly.",
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(color: Colors.grey.shade600),
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

  void _showPaymentErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Payment Failed",
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        content: Text(
          error,
          style: GoogleFonts.manrope(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Try Again"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text("Go Back"),
          ),
        ],
      ),
    );
  }

  void _showPaymentCancelledDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Payment Cancelled",
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Your payment was cancelled. You can try again or go back to modify your booking.",
          style: GoogleFonts.manrope(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Try Again"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text("Go Back"),
          ),
        ],
      ),
    );
  }

  void _showSecurityInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.security, color: Color(0xFF1CABE3)),
            const SizedBox(width: 8),
            Text(
              "Security Information",
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your payment is secure:",
              style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildSecurityPoint("🔒", "256-bit SSL encryption"),
            _buildSecurityPoint("🛡️", "PCI DSS compliant"),
            _buildSecurityPoint("✅", "PayFast certified gateway"),
            _buildSecurityPoint("🏦", "Bank-level security"),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1CABE3),
            ),
            child: Text(
              "Got it",
              style: GoogleFonts.manrope(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityPoint(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.manrope(fontSize: 14),
          ),
        ],
      ),
    );
  }
}