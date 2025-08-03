// lib/services/pricing_service.dart
class PricingService {
  // Base prices for different property types (in ZAR)
  static const Map<String, double> _propertyBasePrices = {
    'Apartment': 300.0,
    'House': 450.0,
    'Cottage': 380.0,
  };

  // Room multipliers
  static const double _bedroomPrice = 50.0;
  static const double _bathroomPrice = 40.0;

  // Cleaning type multipliers
  static const Map<String, double> _cleaningTypeMultipliers = {
    'Standard': 1.0,
    'Deep Cleaning': 1.5,
    'Premium Cleaning': 1.8,
    'Move-In/Out': 2.0,
    'Spring Clean': 1.7,
  };

  // Add-on prices
  static const Map<String, double> _addOnPrices = {
    'Inside Oven': 80.0,
    'Fridge': 60.0,
    'Windows': 120.0,
    'Pet Hair Removal': 100.0,
  };

  // Time slot pricing adjustments (peak hours cost more)
  static const Map<String, double> _timeSlotMultipliers = {
    '8:00 AM - 10:00 AM': 1.0,
    '10:00 AM - 12:00 PM': 1.1,  // Peak hours
    '12:00 PM - 2:00 PM': 1.15,  // Peak hours
    '2:00 PM - 4:00 PM': 1.1,    // Peak hours
    '4:00 PM - 6:00 PM': 1.0,
  };

  // Weekend pricing adjustment
  static const double _weekendMultiplier = 1.2;

  // Same cleaner premium
  static const double _sameCleanerFee = 50.0;

  /// Calculate total price based on booking data
  static PriceBreakdown calculatePrice(Map<String, dynamic> bookingData) {
    double basePrice = 0.0;
    double roomsPrice = 0.0;
    double cleaningMultiplier = 1.0;
    double addOnsPrice = 0.0;
    double timeMultiplier = 1.0;
    double weekendMultiplier = 1.0;
    double sameCleanerFee = 0.0;

    // 1. Base price for property type
    final propertyType = bookingData['propertyType'] as String?;
    if (propertyType != null && _propertyBasePrices.containsKey(propertyType)) {
      basePrice = _propertyBasePrices[propertyType]!;
    }

    // 2. Additional rooms pricing
    final bedrooms = (bookingData['bedrooms'] as int?) ?? 1;
    final bathrooms = (bookingData['bathrooms'] as int?) ?? 1;

    // Charge for rooms beyond the base (1 bedroom, 1 bathroom included)
    final extraBedrooms = (bedrooms - 1).clamp(0, 10);
    final extraBathrooms = (bathrooms - 1).clamp(0, 10);

    roomsPrice = (extraBedrooms * _bedroomPrice) + (extraBathrooms * _bathroomPrice);

    // 3. Cleaning type multiplier
    final cleaningType = bookingData['cleaningType'] as String?;
    if (cleaningType != null && _cleaningTypeMultipliers.containsKey(cleaningType)) {
      cleaningMultiplier = _cleaningTypeMultipliers[cleaningType]!;
    }

    // 4. Add-ons pricing
    final addOns = bookingData['addOns'] as Map<String, dynamic>?;
    if (addOns != null) {
      for (final entry in addOns.entries) {
        if (entry.value == true && _addOnPrices.containsKey(entry.key)) {
          addOnsPrice += _addOnPrices[entry.key]!;
        }
      }
    }

    // 5. Time slot pricing
    final selectedTime = bookingData['selectedTime'] as String?;
    if (selectedTime != null && _timeSlotMultipliers.containsKey(selectedTime)) {
      timeMultiplier = _timeSlotMultipliers[selectedTime]!;
    }

    // 6. Weekend pricing
    final selectedDateString = bookingData['selectedDate'] as String?;
    if (selectedDateString != null) {
      try {
        final selectedDate = DateTime.parse(selectedDateString);
        if (selectedDate.weekday == DateTime.saturday || selectedDate.weekday == DateTime.sunday) {
          weekendMultiplier = _weekendMultiplier;
        }
      } catch (e) {
        // Handle date parsing error gracefully
      }
    }

    // 7. Same cleaner fee
    final sameCleaner = bookingData['sameCleaner'] as bool?;
    if (sameCleaner == true) {
      sameCleanerFee = _sameCleanerFee;
    }

    // Calculate subtotal
    final subtotal = (basePrice + roomsPrice) * cleaningMultiplier * timeMultiplier * weekendMultiplier;

    // Calculate total
    final total = subtotal + addOnsPrice + sameCleanerFee;

    return PriceBreakdown(
      basePrice: basePrice,
      roomsPrice: roomsPrice,
      cleaningMultiplier: cleaningMultiplier,
      addOnsPrice: addOnsPrice,
      timeMultiplier: timeMultiplier,
      weekendMultiplier: weekendMultiplier,
      sameCleanerFee: sameCleanerFee,
      subtotal: subtotal,
      total: total,
      propertyType: propertyType,
      cleaningType: cleaningType,
      selectedTime: selectedTime,
      isWeekend: weekendMultiplier > 1.0,
      selectedAddOns: _getSelectedAddOns(addOns),
    );
  }

  static List<String> _getSelectedAddOns(Map<String, dynamic>? addOns) {
    if (addOns == null) return [];
    return addOns.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get estimated duration for cleaning type
  static int getEstimatedDuration(String? cleaningType) {
    switch (cleaningType?.toLowerCase()) {
      case 'standard':
        return 120; // 2 hours
      case 'deep cleaning':
        return 240; // 4 hours
      case 'premium cleaning':
        return 300; // 5 hours
      case 'move-in/out':
        return 480; // 8 hours
      case 'spring clean':
        return 360; // 6 hours
      default:
        return 120;
    }
  }

  /// Format price as currency string
  static String formatPrice(double price) {
    return 'R${price.toStringAsFixed(2)}';
  }

  /// Get savings text if any discounts apply
  static String? getSavingsText(PriceBreakdown breakdown) {
    // You could implement promotional logic here
    // For example, discounts for first-time users, bulk bookings, etc.
    return null;
  }
}

/// Data class to hold detailed price breakdown
class PriceBreakdown {
  final double basePrice;
  final double roomsPrice;
  final double cleaningMultiplier;
  final double addOnsPrice;
  final double timeMultiplier;
  final double weekendMultiplier;
  final double sameCleanerFee;
  final double subtotal;
  final double total;

  // Additional info for display
  final String? propertyType;
  final String? cleaningType;
  final String? selectedTime;
  final bool isWeekend;
  final List<String> selectedAddOns;

  const PriceBreakdown({
    required this.basePrice,
    required this.roomsPrice,
    required this.cleaningMultiplier,
    required this.addOnsPrice,
    required this.timeMultiplier,
    required this.weekendMultiplier,
    required this.sameCleanerFee,
    required this.subtotal,
    required this.total,
    this.propertyType,
    this.cleaningType,
    this.selectedTime,
    required this.isWeekend,
    required this.selectedAddOns,
  });

  /// Check if booking has any data for pricing
  bool get hasValidData => basePrice > 0;

  /// Get service duration in hours
  double get estimatedHours => PricingService.getEstimatedDuration(cleaningType) / 60.0;

  /// Get price per hour
  double get pricePerHour => estimatedHours > 0 ? total / estimatedHours : 0;
}