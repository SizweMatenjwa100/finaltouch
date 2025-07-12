import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Package_card.dart';
import 'Servicecard.dart';

class Mainbooking extends StatelessWidget {
  const Mainbooking({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: Icon(Icons.arrow_back),
        title: Text("Select a Service",style: GoogleFonts.manrope(fontWeight: FontWeight.bold),textAlign: TextAlign.center,),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
        child: SingleChildScrollView(
          child:Column(
        children: [
          Row(
            children: [
              OutlinedButton(onPressed: (){},
                style: OutlinedButton.styleFrom(backgroundColor: Color(0xFFF1F3F4),
                  side: BorderSide(color:Color(0xFFF1F3F4))
                ),
                  child: Text("All",style:GoogleFonts.manrope(color:Colors.black),
                  ),
              ),
              SizedBox(width: 5,),
              OutlinedButton(onPressed: (){},style:OutlinedButton.styleFrom(
                backgroundColor: Color(0xFFF1F3F4),
                side: BorderSide(color:Color(0xFFF1F3F4))
              ), child: Text("Home", style:GoogleFonts.manrope(color:Colors.black))),
              SizedBox(width: 5,),
              OutlinedButton(onPressed: (){},style:OutlinedButton.styleFrom(
                backgroundColor: Color(0xFFF1F3F4),
                side: BorderSide(color:Color(0xFFF1F3F4))
              ), child: Text("Car", style: GoogleFonts.manrope(color:Colors.black),

              ),
              ),
              SizedBox(width: 5,),



            ],
          ),
          SizedBox(height: 20,),
          PackageCard(name: "Home Cleaning", description: "Book a home deep clean" ,image: 'assets/images/Homecleaning.png'),
          SizedBox(height: 20,),
          PackageCard(name: "Carwash", description: "Book a car wash", image: "assets/images/carwash.png"),
          SizedBox(height: 20,),
          PackageCard(name: "Office Cleaning", description: "Book an office deep clean", image: 'assets/images/Office.png')
        ],

          ),
        ),
      ),
    );

  }
}
