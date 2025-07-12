import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class Showbooking extends StatelessWidget {
  const Showbooking({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 110, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Monday, Dec 25",style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold,),
          ),
          SizedBox(height: 5,),
          Text("Details: Full home cleaning. Address: 123 Main St",style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.normal, color: Color(0xff61758A)),
          ),
          SizedBox(height: 5,),
          Text("Time: 4:00 PM - 6:00 PM",style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.normal, color: Color(0xff61758A)),
          ),

        ],
      ),
    );
  }
}
