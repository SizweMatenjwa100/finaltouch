// lib/presentation/payment/pages/simple_payment_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../features/payment/logic/payment_bloc.dart';
import '../../../features/payment/logic/payment_event.dart';
import '../../../features/payment/logic/payment_state.dart';
import '../../../services/pricing_service.dart';

class SimplePaymentTest extends StatelessWidget {
  final String bookingId;
  final String locationId;
  final Map<String, dynamic> bookingData;

  const SimplePaymentTest({
    super.key,
    required this.bookingId,
    required this.locationId,
    required this.bookingData,
  });

  @override
  Widget build(BuildContext context) {
    // Debug print the received data
    print("🐛 Payment Test Screen - Received Data:");
    print("📊 Booking Data: $bookingData");
    print("🆔 Booking ID: $bookingId");
    print("📍 Location ID: $locationId");

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
          "Payment Test",
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: BlocListener<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentInitiated) {
            _showPaymentDetails(context, state);
          } else if (state is PaymentFailed) {
            _showError(context, state.error);
          }
        },
        child: BlocBuilder<PaymentBloc, PaymentState>(
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Debug info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Debug Information",
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text("Booking ID: $bookingId"),
                        Text("Location ID: $locationId"),
                        Text("Property: ${bookingData['propertyType'] ?? 'NOT SET'}"),
                        Text("Bedrooms: ${bookingData['bedrooms'] ?? 'NOT SET'}"),
                        Text("Bathrooms: ${bookingData['bathrooms'] ?? 'NOT SET'}"),
                        Text("Service: ${bookingData['cleaningType'] ?? 'NOT SET'}"),
                        Text("Date: ${bookingData['selectedDate'] ?? 'NOT SET'}"),
                        Text("Time: ${bookingData['selectedTime'] ?? 'NOT SET'}"),
                        const SizedBox(height: 8),
                        Text(
                          "Raw Data Keys: ${bookingData.keys.toList()}",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Price calculation
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Price Calculation",
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildPriceCalculation(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Test payment button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: state is PaymentLoading ? null : () => _testPayment(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1CABE3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: state is PaymentLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                        "Test Payment Integration",
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // State display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Current State:",
                          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(_getStateDescription(state)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPriceCalculation() {
    print("💰 Calculating price with data: $bookingData");

    // Check if we have the required data for pricing
    if (bookingData['propertyType'] == null || bookingData['cleaningType'] == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "❌ Cannot calculate price - missing required data:",
            style: GoogleFonts.manrope(color: Colors.red),
          ),
          Text("Property Type: ${bookingData['propertyType'] ?? 'MISSING'}"),
          Text("Cleaning Type: ${bookingData['cleaningType'] ?? 'MISSING'}"),
          Text("Bedrooms: ${bookingData['bedrooms'] ?? 'MISSING'}"),
          Text("Bathrooms: ${bookingData['bathrooms'] ?? 'MISSING'}"),
        ],
      );
    }

    final priceBreakdown = PricingService.calculatePrice(bookingData);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("✅ Price calculation successful!"),
        Text("Base Price: ${PricingService.formatPrice(priceBreakdown.basePrice)}"),
        if (priceBreakdown.roomsPrice > 0)
          Text("Extra Rooms: ${PricingService.formatPrice(priceBreakdown.roomsPrice)}"),
        if (priceBreakdown.addOnsPrice > 0)
          Text("Add-ons: ${PricingService.formatPrice(priceBreakdown.addOnsPrice)}"),
        if (priceBreakdown.sameCleanerFee > 0)
          Text("Same Cleaner: ${PricingService.formatPrice(priceBreakdown.sameCleanerFee)}"),
        const Divider(),
        Text(
          "Total: ${PricingService.formatPrice(priceBreakdown.total)}",
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  void _testPayment(BuildContext context) {
    print("🧪 Testing payment with booking data: $bookingData");

    // Check if we have minimum required data
    if (bookingData['propertyType'] == null || bookingData['cleaningType'] == null) {
      _showError(context, "Missing required booking data for payment. Please go back and complete the booking form.");
      return;
    }

    final priceBreakdown = PricingService.calculatePrice(bookingData);

    if (priceBreakdown.total < 5.0) {
      _showError(context, "Payment amount (${PricingService.formatPrice(priceBreakdown.total)}) is below minimum (R5.00)");
      return;
    }

    print("🧪 Testing payment with amount: ${priceBreakdown.total}");

    context.read<PaymentBloc>().add(
      InitiatePayment(
        bookingId: bookingId,
        locationId: locationId,
        amount: priceBreakdown.total,
        itemName: "Final Touch Cleaning Service",
        itemDescription: "${bookingData['cleaningType']} - ${bookingData['propertyType']}",
        bookingData: bookingData,
      ),
    );
  }

  String _getStateDescription(PaymentState state) {
    if (state is PaymentInitial) return "Ready to test payment";
    if (state is PaymentLoading) return "Processing payment...";
    if (state is PaymentInitiated) return "Payment initiated successfully! Check debug info below.";
    if (state is PaymentFailed) return "Payment failed: ${state.error}";
    if (state is PaymentSuccess) return "Payment successful!";
    return state.toString();
  }

  void _showPaymentDetails(BuildContext context, PaymentInitiated state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Payment Details Generated",
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("✅ Order ID: ${state.merchantOrderId}"),
              const SizedBox(height: 8),
              Text("✅ Payment URL: ${state.paymentUrl}"),
              const SizedBox(height: 8),
              Text("✅ Payment Data:"),
              const SizedBox(height: 4),
              ...state.paymentData.entries.map((entry) =>
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 2),
                    child: Text("${entry.key}: ${entry.value}"),
                  ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Here you could implement the actual PayFast redirect
              _simulatePaymentSuccess(context, state.merchantOrderId);
            },
            child: Text("Simulate Success"),
          ),
        ],
      ),
    );
  }

  void _simulatePaymentSuccess(BuildContext context, String orderId) {
    // Simulate a successful payment callback
    context.read<PaymentBloc>().add(
      ProcessPaymentCallback(
        merchantOrderId: orderId,
        paymentStatus: 'complete',
        callbackData: {
          'm_payment_id': orderId,
          'payment_status': 'COMPLETE',
          'item_name': 'Final Touch Cleaning Service',
          'amount_gross': bookingData['totalPrice']?.toString() ?? '0.00',
        },
      ),
    );
  }

  void _showError(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Payment Error",
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        content: Text(error),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }
}