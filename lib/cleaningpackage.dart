import 'package:finaltouch/Package_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Cleaningpackage extends StatelessWidget {
  const Cleaningpackage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Office Cleaning",style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 24), textAlign: TextAlign.start,maxLines: 2,),
        leading: Icon(Icons.arrow_back),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(

        children: [
          PackageCard(name: "Basic Package", description: "For regular upkeep and cleanliness", image: 'assets/images/basicpackage.png'),
          SizedBox(height: 3,),
          PackageCard(name: "Standard Package", description: "Thorough cleaning with detailed focus.", image: 'assets/images/standardpackage.png'),
          SizedBox(height: 3,),
          PackageCard(name: "Premium Package", description: "For a comprehensive, high-detail clean.", image: 'assets/images/premiumpackage.png'),


        ],
      ),
    );
  }
}
