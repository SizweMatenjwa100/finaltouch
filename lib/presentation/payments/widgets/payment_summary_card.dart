
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/pricing_service.dart';

class PaymentSummaryCard extends StatelessWidget {
  final Map<String, dynamic> bookingData;
  final PriceBreakdown priceBreakdown;

  const PaymentSummaryCard({
    super.key,
    required this.bookingData,
    required this.priceBreakdown,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        border: Border.all(color: const Color(0xFF1CABE3).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1CABE3).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1CABE3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.receipt_long,
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
                        "Booking Summary",
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1CABE3),
                        ),
                      ),
                      if (priceBreakdown.estimatedHours > 0)
                        Text(
                          "Est. ${priceBreakdown.estimatedHours.toStringAsFixed(1)} hours",
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                // Total amount badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1CABE3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    PricingService.formatPrice(priceBreakdown.total),
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            // Booking details
            _buildSummaryRow(
              Icons.cleaning_services,
              "Service",
              bookingData['cleaningType'] ?? 'Standard Cleaning',
            ),

            _buildSummaryRow(
              Icons.home,
              "Property",
              "${bookingData['propertyType'] ?? 'Property'} • ${bookingData['bedrooms'] ?? 1} bed • ${bookingData['bathrooms'] ?? 1} bath",
            ),

            if (bookingData['selectedDate'] != null)
              _buildSummaryRow(
                Icons.calendar_today,
                "Date & Time",
                "${_formatDate(bookingData['selectedDate'])} at ${bookingData['selectedTime'] ?? 'Time not set'}",
              ),

            if (_getSelectedAddOns().isNotEmpty)
              _buildSummaryRow(
                Icons.add_circle_outline,
                "Add-ons",
                _getSelectedAddOns().join(", "),
              ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Price breakdown
            _buildPriceRow(
              "Base Price",
              PricingService.formatPrice(priceBreakdown.basePrice),
              subtitle: priceBreakdown.propertyType,
            ),

            if (priceBreakdown.roomsPrice > 0)
              _buildPriceRow(
                "Additional Rooms",
                PricingService.formatPrice(priceBreakdown.roomsPrice),
                subtitle: "Extra bedrooms & bathrooms",
              ),

            if (priceBreakdown.cleaningMultiplier != 1.0)
              _buildPriceRow(
                "Service Premium",
                "${((priceBreakdown.cleaningMultiplier - 1) * 100).toStringAsFixed(0)}%",
                subtitle: priceBreakdown.cleaningType,
              ),

            if (priceBreakdown.timeMultiplier != 1.0)
              _buildPriceRow(
                "Peak Hours",
                "${((priceBreakdown.timeMultiplier - 1) * 100).toStringAsFixed(0)}%",
                subtitle: priceBreakdown.selectedTime,
              ),

            if (priceBreakdown.isWeekend)
              _buildPriceRow(
                "Weekend Service",
                "${((priceBreakdown.weekendMultiplier - 1) * 100).toStringAsFixed(0)}%",
                subtitle: "Saturday/Sunday",
              ),

            if (priceBreakdown.addOnsPrice > 0)
              _buildPriceRow(
                "Add-ons",
                PricingService.formatPrice(priceBreakdown.addOnsPrice),
              ),

            if (priceBreakdown.sameCleanerFee > 0)
              _buildPriceRow(
                "Same Cleaner",
                PricingService.formatPrice(priceBreakdown.sameCleanerFee),
              ),

            const SizedBox(height: 16),
            const Divider(thickness: 2),
            const SizedBox(height: 16),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total Amount",
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (priceBreakdown.estimatedHours > 0)
                      Text(
                        "${PricingService.formatPrice(priceBreakdown.pricePerHour)} per hour",
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
                Text(
                  PricingService.formatPrice(priceBreakdown.total),
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1CABE3),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            "$label:",
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 8),
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
      ),
    );
  }

  Widget _buildPriceRow(String label, String price, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            price,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1CABE3),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getSelectedAddOns() {
    final addOns = bookingData['addOns'] as Map<String, dynamic>?;
    if (addOns == null) return [];

    return addOns.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];

      return "${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}";
    } catch (e) {
      return dateString;
    }
  }
}