import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // left-align the title
      children: [
        Text(
          "Add-ons",
          style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),

        ...addOns.keys.map((title) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: CheckboxListTile(
              title: Text(
                title,
                style: GoogleFonts.manrope(fontSize: 16),
              ),
              value: addOns[title],
              onChanged: (bool? newValue) {
                setState(() {
                  addOns[title] = newValue!;
                });
              },
              controlAffinity: ListTileControlAffinity.trailing,
              contentPadding: EdgeInsets.symmetric(horizontal: 10),
              dense: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: Colors.white,
              checkColor: Colors.white,
              activeColor: Color(0xFF1CABE3),

            ),
          );
        }).toList(),
      ],
    );
  }
}
