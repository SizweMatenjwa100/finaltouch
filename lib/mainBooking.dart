import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:finaltouch/presentation/booking/pages/Homecleaning_booking.dart';

class MainBooking extends StatefulWidget {
  const MainBooking({super.key});

  @override
  State<MainBooking> createState() => _MainBookingState();
}

class _MainBookingState extends State<MainBooking> {
  String selectedCategory = "All";

  final List<String> categories = ["All", "Home", "Car", "Office"];

  final List<ServiceItem> services = [
    ServiceItem(
      name: "Home Cleaning",
      description: "Professional home cleaning services for your comfort",
      image: 'assets/images/Homecleaning.png',
      category: "Home",
      duration: "2-4 hours",
      isAvailable: true,
      features: ["Deep cleaning", "Eco-friendly", "Insured cleaners"],
      onTap: () {},
    ),
    ServiceItem(
      name: "Laundry Service",
      description: "Professional washing, drying, and folding service",
      image: 'assets/images/service_laundry.png',
      category: "Home",
      duration: "Same day",
      isAvailable: true,
      features: ["Wash & fold", "Pick up & drop", "Fabric care"],
      onTap: () {},
    ),
    ServiceItem(
      name: "Mobile Carwash",
      description: "Professional car cleaning at your location",
      image: 'assets/images/carwash.png',
      category: "Car",
      duration: "1-2 hours",
      isAvailable: false,
      comingSoonDate: "March 2025",
      features: ["Interior & exterior", "Wax protection", "Mobile service"],
      onTap: () {},
    ),
    ServiceItem(
      name: "Office Cleaning",
      description: "Keep your workspace clean and professional",
      image: 'assets/images/Office.png',
      category: "Office",
      duration: "2-3 hours",
      isAvailable: false,
      comingSoonDate: "April 2025",
      features: ["After hours", "Sanitization", "Regular schedules"],
      onTap: () {},
    ),
  ];

  List<ServiceItem> get filteredServices {
    if (selectedCategory == "All") {
      return services;
    }
    return services.where((service) => service.category == selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Select a Service",
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.grey.shade700),
            onPressed: () {
              // Navigate to search screen
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "What service do you need today?",
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Choose from our professional cleaning services",
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),

                // Category Filter Chips
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = selectedCategory == category;

                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: FilterChip(
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              selectedCategory = category;
                            });
                          },
                          label: Text(
                            category,
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.grey.shade700,
                            ),
                          ),
                          backgroundColor: Colors.grey.shade200,
                          selectedColor: const Color(0xFF1CABE3),
                          checkmarkColor: Colors.white,
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Services List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredServices.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildServiceCard(filteredServices[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(ServiceItem service) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: service.isAvailable
              ? () {
            if (service.name == "Home Cleaning") {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomecleaningBooking()),
              );
            } else {
              service.onTap();
            }
          }
              : () => _showComingSoonDialog(service),
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Service Image
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: service.isAvailable ? null : Colors.grey.shade200,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ColorFiltered(
                          colorFilter: service.isAvailable
                              ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                              : ColorFilter.mode(Colors.grey.shade400, BlendMode.saturation),
                          child: Image.asset(
                            service.image,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Service Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  service.name,
                                  style: GoogleFonts.manrope(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: service.isAvailable ? Colors.black : Colors.grey.shade500,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Text(
                            service.description,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: service.isAvailable ? Colors.grey.shade600 : Colors.grey.shade400,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 12),

                          if (service.isAvailable) ...[
                            // Service Info Row
                            Row(
                              children: [
                                _buildInfoChip(Icons.access_time, service.duration),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Features
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: service.features.take(2).map((feature) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1CABE3).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  feature,
                                  style: GoogleFonts.manrope(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF1CABE3),
                                  ),
                                ),
                              )).toList(),
                            ),
                          ] else ...[
                            // Coming Soon Info
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: Colors.orange.shade700,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Coming Soon - ${service.comingSoonDate}",
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Action Button
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: service.isAvailable
                            ? const Color(0xFF1CABE3)
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        service.isAvailable ? Icons.arrow_forward : Icons.schedule,
                        color: service.isAvailable ? Colors.white : Colors.grey.shade500,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // Coming Soon Overlay
              if (!service.isAvailable)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "COMING SOON",
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(ServiceItem service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.schedule,
                color: Colors.orange.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Coming Soon!",
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              service.name,
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              service.description,
              style: GoogleFonts.manrope(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1CABE3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1CABE3).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.rocket_launch,
                    color: const Color(0xFF1CABE3),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Expected Launch",
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1CABE3),
                    ),
                  ),
                  Text(
                    service.comingSoonDate ?? "Soon",
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1CABE3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "We're working hard to bring you this service. Get notified when it's available!",
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Close",
              style: GoogleFonts.manrope(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("You'll be notified when ${service.name} is available!"),
                  backgroundColor: const Color(0xFF1CABE3),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1CABE3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              "Notify Me",
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ServiceItem {
  final String name;
  final String description;
  final String image;
  final String category;
  final String duration;
  final bool isAvailable;
  final String? comingSoonDate;
  final List<String> features;
  final VoidCallback onTap;

  ServiceItem({
    required this.name,
    required this.description,
    required this.image,
    required this.category,
    required this.duration,
    required this.isAvailable,
    this.comingSoonDate,
    required this.features,
    required this.onTap,
  });
}