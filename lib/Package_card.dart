import 'package:finaltouch/presentation/booking/pages/Homecleaning_booking.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PackageCard extends StatelessWidget {
  final String name;
  final String description;
  final String image;
  const PackageCard({super.key, required this.name, required this.description,required this.image});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),

      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black12)],

        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(image, fit: BoxFit.cover,),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(name,style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.start,),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(description,style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.normal, fontSize: 16), textAlign: TextAlign.start,maxLines: 2,),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(onPressed: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>HomecleaningBooking()));

                },style: OutlinedButton.styleFrom(
                  backgroundColor: Color(0xFF1CABE3),
                  side: BorderSide( color:Color(0xFF1CABE3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                  child: Text("select", style:
                  GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),

                  ),

                ),
              ),
            )

          ],
        ),
      ),
    );
  }
  }