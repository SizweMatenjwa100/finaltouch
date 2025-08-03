// lib/presentation/booking/widgets/dynamic_pricing_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../features/booking/logic/booking_bloc.dart';
import '../../../features/booking/logic/booking_state.dart';
import '../../../services/pricing_service.dart';

class DynamicPricingWidget extends StatelessWidget {
  final bool showDetails;
  final bool isCompact;

  const DynamicPricingWidget({
    super.key,
    this.showDetails = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        final bookingData = context.read<BookingBloc>().currentBookingData;
        final priceBreakdown = PricingService.calculatePrice(bookingData);

        if (!priceBreakdown.hasValidData) {
          return _buildEmptyState();
        }

        return isCompact
            ? _buildCompactPricing(priceBreakdown)
            : _buildDetailedPricing(priceBreakdown);
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.calculate_outlined, color: Colors.grey.shade400, size: 20),
          const SizedBox(width: 8),
          Text(
            "Select services to see pricing",
            style: GoogleFonts.manrope(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactPricing(PriceBreakdown breakdown) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1CABE3).withOpacity(0.1),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1CABE3).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.monetization_on,
            color: const Color(0xFF1CABE3),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Estimated Total",
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.grey.shade600,
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
          ),
          if (breakdown.estimatedHours > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${breakdown.estimatedHours.toStringAsFixed(1)}h",
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  "${PricingService.formatPrice(breakdown.pricePerHour)}/h",
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDetailedPricing(PriceBreakdown breakdown) {
    return Container(
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
                    Icons.calculate,
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
                        "Price Estimate",
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1CABE3),
                        ),
                      ),
                      if (breakdown.estimatedHours > 0)
                        Text(
                          "Estimated ${breakdown.estimatedHours.toStringAsFixed(1)} hours",
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                // Total price badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1CABE3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    PricingService.formatPrice(breakdown.total),
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            if (showDetails) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),

              // Price breakdown
              _buildPriceRow(
                "Base Price",
                PricingService.formatPrice(breakdown.basePrice),
                subtitle: breakdown.propertyType,
              ),

              if (breakdown.roomsPrice > 0)
                _buildPriceRow(
                  "Additional Rooms",
                  PricingService.formatPrice(breakdown.roomsPrice),
                  subtitle: "Extra bedrooms & bathrooms",
                ),

              if (breakdown.cleaningMultiplier != 1.0)
                _buildPriceRow(
                  "Service Type",
                  "${((breakdown.cleaningMultiplier - 1) * 100).toStringAsFixed(0)}% premium",
                  subtitle: breakdown.cleaningType,
                ),

              if (breakdown.timeMultiplier != 1.0)
                _buildPriceRow(
                  "Peak Hours",
                  "${((breakdown.timeMultiplier - 1) * 100).toStringAsFixed(0)}% premium",
                  subtitle: breakdown.selectedTime,
                ),

              if (breakdown.isWeekend)
                _buildPriceRow(
                  "Weekend Service",
                  "${((breakdown.weekendMultiplier - 1) * 100).toStringAsFixed(0)}% premium",
                  subtitle: "Saturday/Sunday",
                ),

              if (breakdown.addOnsPrice > 0) ...[
                _buildPriceRow(
                  "Add-ons",
                  PricingService.formatPrice(breakdown.addOnsPrice),
                ),
                const SizedBox(height: 4),
                ...breakdown.selectedAddOns.map((addon) => Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1CABE3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        addon,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )),
              ],

              if (breakdown.sameCleanerFee > 0)
                _buildPriceRow(
                  "Same Cleaner Request",
                  PricingService.formatPrice(breakdown.sameCleanerFee),
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
                      if (breakdown.estimatedHours > 0)
                        Text(
                          "${PricingService.formatPrice(breakdown.pricePerHour)} per hour",
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                  Text(
                    PricingService.formatPrice(breakdown.total),
                    style: GoogleFonts.manrope(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1CABE3),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Disclaimer
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Final price may vary based on property condition and actual cleaning requirements.",
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
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
}