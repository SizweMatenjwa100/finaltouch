// lib/presentation/booking/widgets/AddOns.dart - FIXED VERSION
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../features/booking/logic/booking_bloc.dart';
import '../../../features/booking/logic/booking_event.dart';
import '../../../features/booking/logic/booking_state.dart';

class Addons extends StatefulWidget {
  const Addons({super.key});

  @override
  State<Addons> createState() => _AddonsState();
}

class _AddonsState extends State<Addons> {
  Map<String, bool> addOns = {
    'Inside Oven': false,
    'Fridge': false,
    'Windows': false,
    'Pet Hair Removal': false,
  };

  void _updateBookingData() {
    print("🔧 Updating add-ons: $addOns");
    context.read<BookingBloc>().add(
      SetAddOns(addOns: Map.from(addOns)),
    );
  }

  @override
  void initState() {
    super.initState();
    // Initialize add-ons in the bloc
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateBookingData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BookingBloc, BookingState>(
      listener: (context, state) {
        if (state is BookingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Add-ons (Optional)",
            style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Select any additional services you'd like",
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),

          // Add-ons list
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: addOns.keys.map((title) {
                final isSelected = addOns[title] ?? false;
                return Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1CABE3).withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(4),
                  child: CheckboxListTile(
                    title: Text(
                      title,
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? const Color(0xFF1CABE3) : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      _getAddOnDescription(title),
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    value: addOns[title],
                    onChanged: (bool? newValue) {
                      setState(() {
                        addOns[title] = newValue ?? false;
                      });
                      _updateBookingData();
                    },
                    controlAffinity: ListTileControlAffinity.trailing,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    dense: false,
                    checkColor: Colors.white,
                    activeColor: const Color(0xFF1CABE3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Selected add-ons summary
          BlocBuilder<BookingBloc, BookingState>(
            builder: (context, state) {
              final data = context.read<BookingBloc>().currentBookingData;
              if (data.containsKey('addOns')) {
                final selectedAddOns = Map<String, bool>.from(data['addOns']);
                final selectedItems = selectedAddOns.entries
                    .where((entry) => entry.value)
                    .map((entry) => entry.key)
                    .toList();

                if (selectedItems.isNotEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1CABE3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF1CABE3).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              color: const Color(0xFF1CABE3),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Selected Add-ons (${selectedItems.length}):",
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: const Color(0xFF1CABE3),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: selectedItems.map((item) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1CABE3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              item,
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )).toList(),
                        ),
                      ],
                    ),
                  );
                } else {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.grey.shade500,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "No add-ons selected",
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  String _getAddOnDescription(String addOn) {
    switch (addOn) {
      case 'Inside Oven':
        return 'Deep clean inside your oven';
      case 'Fridge':
        return 'Clean inside and outside of refrigerator';
      case 'Windows':
        return 'Clean interior window surfaces';
      case 'Pet Hair Removal':
        return 'Specialized pet hair removal from furniture';
      default:
        return '';
    }
  }
}