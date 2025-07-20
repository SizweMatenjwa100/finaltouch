import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WidgetStep extends StatefulWidget {
  const WidgetStep({super.key});

  @override
  State<WidgetStep> createState() => _WidgetStepState();
}

class _WidgetStepState extends State<WidgetStep> {
  int _bedrooms = 1;
  int _bathrooms = 1;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            "Property Info",
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Dropdown
          DropdownButtonFormField(
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              fillColor: Color(0xFFF5F5F5), // Soft grey fill
              filled: true,
              hintText: "Select Property Type",
              hintStyle: GoogleFonts.manrope(
                fontWeight: FontWeight.w800,
                color: Colors.black,
                fontSize: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
              ),
            ),
            items: ['Apartment', 'House', 'Cottage'].map((e) {
              return DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.manrope()));
            }).toList(),
            onChanged: (val) {},
          ),

          const SizedBox(height: 30),

          // Bedrooms
          Row(
            children: [
              Text(
                "Bedrooms",
                style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  setState(() {
                    if (_bedrooms > 1) _bedrooms--;
                  });
                },
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text(
                "$_bedrooms",
                style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _bedrooms++;
                  });
                },
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Bathrooms
          Row(
            children: [
              Text(
                "Bathrooms",
                style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  setState(() {
                    if (_bathrooms > 1) _bathrooms--;
                  });
                },
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text(
                "$_bathrooms",
                style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _bathrooms++;
                  });
                },
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
