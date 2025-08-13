import 'package:finaltouch/cleaningpackage.dart';
import 'package:finaltouch/main_navigation.dart';
import 'package:finaltouch/presentation/booking/pages/Homecleaning_booking.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Searchscreen extends StatefulWidget {
  const Searchscreen({super.key});

  @override
  State<Searchscreen> createState() => _SearchscreenState();
}

class _SearchscreenState extends State<Searchscreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ServiceItem> _allServices = [];
  List<ServiceItem> _filteredServices = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _initializeServices() {
    _allServices = [
      ServiceItem(
        name: "Home Cleaning",
        description: "Professional home cleaning services for your comfort",
        category: "Home",
        icon: Icons.home,
        image: 'assets/images/Homecleaning.png',
        duration: "2-4 hours",
        isAvailable: true,
        features: ["Deep cleaning", "Eco-friendly", "Insured cleaners"],
        onTap: () => _navigateToBooking("Home Cleaning"),
      ),
      ServiceItem(
        name: "Laundry Service",
        description: "Professional washing, drying, and folding service",
        category: "Home",
        icon: Icons.local_laundry_service,
        image: 'assets/images/service_laundry.png',
        duration: "Same day",
        isAvailable: true,
        features: ["Wash & fold", "Pick up & drop", "Fabric care"],
        onTap: () => _navigateToBooking("Laundry Service"),
      ),
      ServiceItem(
        name: "Mobile Carwash",
        description: "Professional car cleaning at your location",
        category: "Car",
        icon: Icons.directions_car,
        image: 'assets/images/carwash.png',
        duration: "1-2 hours",
        isAvailable: false,
        comingSoonDate: "March 2025",
        features: ["Interior & exterior", "Wax protection", "Mobile service"],
        onTap: () => _navigateToBooking("Car Wash"),
      ),
      ServiceItem(
        name: "Office Cleaning",
        description: "Keep your workspace clean and professional",
        category: "Office",
        icon: Icons.business,
        image: 'assets/images/Office.png',
        duration: "2-3 hours",
        isAvailable: false,
        comingSoonDate: "April 2025",
        features: ["After hours", "Sanitization", "Regular schedules"],
        onTap: () => _navigateToOfficePackages(),
      ),
    ];
    _filteredServices = List.from(_allServices);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      setState(() {
        _filteredServices = List.from(_allServices);
        _isSearching = false;
      });
    } else {
      setState(() {
        _isSearching = true;
        _filteredServices = _allServices.where((service) {
          return service.name.toLowerCase().contains(query) ||
              service.description.toLowerCase().contains(query) ||
              service.category.toLowerCase().contains(query) ||
              service.features.any((feature) => feature.toLowerCase().contains(query));
        }).toList();
      });
    }
  }

  void _navigateToBooking(String serviceName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HomecleaningBooking(),
      ),
    );
  }

  void _navigateToOfficePackages() {

  }

  void _clearSearch() {
    _searchController.clear();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MainNavigation(),
              ),
            );
          },
        ),
        title: Text(
          "Search Services",
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _searchController,
                cursorColor: const Color(0xFF1CABE3),
                style: GoogleFonts.manrope(),
                decoration: InputDecoration(
                  hintText: "Search for a service...",
                  hintStyle: GoogleFonts.manrope(
                    color: Colors.grey[600],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[600],
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.grey[600],
                    ),
                    onPressed: _clearSearch,
                  )
                      : null,
                ),
              ),
            ),
          ),

          // Search Results Header
          if (_isSearching) ...[
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Text(
                    "Search Results",
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "${_filteredServices.length} found",
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Service Categories (when not searching)
          if (!_isSearching) ...[
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Browse Services",
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryChips(),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Services List
          Expanded(
            child: _filteredServices.isEmpty && _isSearching
                ? _buildNoResultsWidget()
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredServices.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildServiceCard(_filteredServices[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = ['All', 'Home', 'Car', 'Office'];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                category,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w600,
                ),
              ),
              selected: false,
              onSelected: (selected) {
                if (category == 'All') {
                  setState(() {
                    _filteredServices = List.from(_allServices);
                  });
                } else {
                  setState(() {
                    _filteredServices = _allServices
                        .where((service) => service.category == category)
                        .toList();
                  });
                }
              },
              backgroundColor: const Color(0xFFF1F3F4),
              selectedColor: const Color(0xFF1CABE3).withOpacity(0.2),
              checkmarkColor: const Color(0xFF1CABE3),
            ),
          );
        },
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
          onTap: service.isAvailable ? service.onTap : () => _showComingSoonDialog(service),
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Service Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: service.isAvailable
                            ? const Color(0xFF1CABE3).withOpacity(0.1)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        service.icon,
                        color: service.isAvailable
                            ? const Color(0xFF1CABE3)
                            : Colors.grey.shade400,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Service Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.name,
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: service.isAvailable ? Colors.black : Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            service.description,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: service.isAvailable ? Colors.grey[600] : Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (service.isAvailable) ...[
                            Row(
                              children: [
                                _buildInfoChip(Icons.access_time, service.duration),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1CABE3).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    service.category,
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1CABE3),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    color: Colors.orange.shade700,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Coming ${service.comingSoonDate}",
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

                    // Arrow Icon
                    Icon(
                      service.isAvailable ? Icons.arrow_forward_ios : Icons.schedule,
                      color: service.isAvailable ? Colors.grey[400] : Colors.orange.shade600,
                      size: 16,
                    ),
                  ],
                ),
              ),

              // Coming Soon Badge
              if (!service.isAvailable)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "COMING SOON",
                      style: GoogleFonts.manrope(
                        fontSize: 8,
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
            size: 12,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              "No services found",
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Try searching with different keywords",
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: _clearSearch,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1CABE3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Clear Search",
                style: GoogleFonts.manrope(
                  color: const Color(0xFF1CABE3),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceItem {
  final String name;
  final String description;
  final String category;
  final IconData icon;
  final String image;
  final String duration;
  final bool isAvailable;
  final String? comingSoonDate;
  final List<String> features;
  final VoidCallback onTap;

  ServiceItem({
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.image,
    required this.duration,
    required this.isAvailable,
    this.comingSoonDate,
    required this.features,
    required this.onTap,
  });
}