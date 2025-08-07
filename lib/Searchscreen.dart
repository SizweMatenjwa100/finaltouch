import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:finaltouch/cleaningpackage.dart';
import 'package:finaltouch/presentation/booking/pages/Homecleaning_booking.dart';

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
        description: "Professional home cleaning services",
        category: "Home",
        icon: Icons.home,
        image: 'assets/images/Homecleaning.png',
        onTap: () => _navigateToBooking("Home Cleaning"),
      ),
      ServiceItem(
        name: "Deep Cleaning",
        description: "Thorough deep cleaning for your home",
        category: "Home",
        icon: Icons.cleaning_services,
        image: 'assets/images/deep_cleaning.png',
        onTap: () => _navigateToBooking("Deep Cleaning"),
      ),
      ServiceItem(
        name: "Office Cleaning",
        description: "Professional office cleaning services",
        category: "Office",
        icon: Icons.business,
        image: 'assets/images/Office.png',
        onTap: () => _navigateToOfficePackages(),
      ),
      ServiceItem(
        name: "Car Wash",
        description: "Mobile car wash services",
        category: "Car",
        icon: Icons.directions_car,
        image: 'assets/images/carwash.png',
        onTap: () => _navigateToBooking("Car Wash"),
      ),
      ServiceItem(
        name: "Carpet Cleaning",
        description: "Professional carpet and upholstery cleaning",
        category: "Home",
        icon: Icons.texture,
        image: 'assets/images/carpet_cleaning.png',
        onTap: () => _navigateToBooking("Carpet Cleaning"),
      ),
      ServiceItem(
        name: "Window Cleaning",
        description: "Interior and exterior window cleaning",
        category: "Home",
        icon: Icons.window,
        image: 'assets/images/window_cleaning.png',
        onTap: () => _navigateToBooking("Window Cleaning"),
      ),
      ServiceItem(
        name: "Laundry Service",
        description: "Professional laundry and ironing",
        category: "Home",
        icon: Icons.local_laundry_service,
        image: 'assets/images/service_laundry.png',
        onTap: () => _navigateToBooking("Laundry Service"),
      ),
      ServiceItem(
        name: "Move-in/Move-out Cleaning",
        description: "Complete cleaning for moving",
        category: "Home",
        icon: Icons.moving,
        image: 'assets/images/move_cleaning.png',
        onTap: () => _navigateToBooking("Move-in/Move-out Cleaning"),
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
              service.category.toLowerCase().contains(query);
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const Cleaningpackage(),
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
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
          Padding(
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
            Padding(
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Text(
                    "Browse Services",
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildCategoryChips(),
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
                return _buildServiceCard(_filteredServices[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = ['All', 'Home', 'Office', 'Car'];

    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
              selected: false, // You can implement category filtering here
              onSelected: (selected) {
                // Implement category filtering
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
      margin: const EdgeInsets.only(bottom: 12),
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
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: service.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Service Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1CABE3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    service.icon,
                    color: const Color(0xFF1CABE3),
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
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service.description,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
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
                ),

                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
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
  final VoidCallback onTap;

  ServiceItem({
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.image,
    required this.onTap,
  });
}