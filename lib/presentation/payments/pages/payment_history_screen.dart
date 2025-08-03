// lib/presentation/payment/pages/payment_history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../features/payment/logic/payment_bloc.dart';
import '../../../features/payment/logic/payment_event.dart';
import '../../../features/payment/logic/payment_state.dart';
import '../../../features/payment/data/payment_repository.dart';
import '../../../services/payfast_service.dart';

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PaymentBloc(
        paymentRepository: PaymentRepository(
          firestore: FirebaseFirestore.instance,
          auth: FirebaseAuth.instance,
        ),
      )..add(LoadPaymentHistory()),
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "Payment History",
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              onPressed: () {
                context.read<PaymentBloc>().add(LoadPaymentHistory());
              },
            ),
          ],
        ),
        body: BlocBuilder<PaymentBloc, PaymentState>(
          builder: (context, state) {
            if (state is PaymentLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF1CABE3)),
              );
            }

            if (state is PaymentError) {
              return _buildErrorState(state.error, context);
            }

            if (state is PaymentHistoryLoaded) {
              if (state.payments.isEmpty) {
                return _buildEmptyState();
              }
              return _buildPaymentsList(state.payments);
            }

            return _buildEmptyState();
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.payment_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              "No Payment History",
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Your payment transactions will appear here after you make bookings",
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                color: Colors.grey.shade500,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
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
              "Error Loading Payments",
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<PaymentBloc>().add(LoadPaymentHistory());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1CABE3),
              ),
              child: Text(
                "Retry",
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsList(List<Map<String, dynamic>> payments) {
    return RefreshIndicator(
      onRefresh: () async {
        // Trigger refresh
      },
      color: const Color(0xFF1CABE3),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: payments.length,
        itemBuilder: (context, index) {
          final payment = payments[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildPaymentCard(payment),
          );
        },
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final status = payment['status'] as String? ?? 'unknown';
    final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
    final merchantOrderId = payment['merchantOrderId'] as String? ?? '';
    final createdAt = payment['createdAt'] as Timestamp?;
    final paymentData = payment['paymentData'] as Map<String, dynamic>?;

    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    String formattedDate = 'Unknown date';
    if (createdAt != null) {
      final date = createdAt.toDate();
      formattedDate = "${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            statusIcon,
            color: statusColor,
            size: 24,
          ),
        ),
        title: Text(
          PayFastService.formatAmount(amount),
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              formattedDate,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getStatusDisplayText(status),
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow("Order ID", merchantOrderId),
                const SizedBox(height: 8),
                _buildDetailRow("Status", PayFastService.getPaymentStatusDescription(status)),
                const SizedBox(height: 8),
                _buildDetailRow("Amount", PayFastService.formatAmount(amount)),

                // Show booking details if available
                if (paymentData != null) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    "Booking Details",
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (paymentData['cleaningType'] != null)
                    _buildDetailRow("Service", paymentData['cleaningType']),
                  if (paymentData['propertyType'] != null)
                    _buildDetailRow("Property", paymentData['propertyType']),
                  if (paymentData['selectedDate'] != null)
                    _buildDetailRow("Date", _formatBookingDate(paymentData['selectedDate'])),
                  if (paymentData['selectedTime'] != null)
                    _buildDetailRow("Time", paymentData['selectedTime']),
                ],

                // Action buttons
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (status.toLowerCase() == 'failed' || status.toLowerCase() == 'cancelled')
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _retryPayment(payment);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF1CABE3)),
                          ),
                          child: Text(
                            "Retry Payment",
                            style: GoogleFonts.manrope(
                              color: const Color(0xFF1CABE3),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    if (status.toLowerCase() == 'complete') ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _downloadReceipt(payment);
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.download, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                "Receipt",
                                style: GoogleFonts.manrope(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'complete':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'cancelled':
        return Colors.orange;
      case 'pending':
      case 'initiated':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'complete':
        return Icons.check_circle;
      case 'failed':
        return Icons.error;
      case 'cancelled':
        return Icons.cancel;
      case 'pending':
      case 'initiated':
        return Icons.hourglass_empty;
      default:
        return Icons.help;
    }
  }

  String _getStatusDisplayText(String status) {
    switch (status.toLowerCase()) {
      case 'complete':
        return 'COMPLETED';
      case 'failed':
        return 'FAILED';
      case 'cancelled':
        return 'CANCELLED';
      case 'pending':
        return 'PENDING';
      case 'initiated':
        return 'INITIATED';
      default:
        return status.toUpperCase();
    }
  }

  String _formatBookingDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return "${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}";
    } catch (e) {
      return dateString;
    }
  }

  void _retryPayment(Map<String, dynamic> payment) {
    // Implement retry payment logic
    // This would typically navigate back to payment screen with the same booking data
  }

  void _downloadReceipt(Map<String, dynamic> payment) {
    // Implement receipt download logic
    // This could generate a PDF receipt or open a receipt view
  }
}