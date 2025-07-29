
import 'package:finaltouch/cleaningpackage.dart';
import 'package:finaltouch/main_navigation.dart';
import 'package:finaltouch/profile.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Searchscreen.dart';
import 'Servicecard.dart';
import 'mainBooking.dart';

class Homepage extends StatefulWidget {

  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 395,
                      width: double.infinity,
                      child: Image.asset('assets/images/homebanner.png', fit: BoxFit.fill)
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(30,40, 0, 0),
                    child: Text("Get your home",style: GoogleFonts.manrope(fontSize: 40, fontWeight: FontWeight.bold, color:  Colors.white),),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(30,90, 0, 0),
                    child: Text("cleaned today", style: GoogleFonts.manrope(fontWeight: FontWeight.bold,fontSize: 40,color:Colors.white),),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(30,150, 0, 0),
                    child: Text("Dishes, laundry, windows, you name it. We'll take care of it.", style:GoogleFonts.manrope(fontSize: 15, color: Colors.white)),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20,325, 0, 0),
                    child: SizedBox(

                      child: OutlinedButton(onPressed: (){
                        Navigator.push(context, MaterialPageRoute(builder: (context)=>Cleaningpackage()));
                      },style: OutlinedButton.styleFrom(
                        backgroundColor: Color(0xFF1CABE3),
                        side: BorderSide( color:Color(0xFF1CABE3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                        child: SizedBox(

                          child: Text("Book now", style:
                          GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),

                          ),
                        ),

                      ),
                    ),
                  ),
                ],

              ),
              SizedBox(height: 20,),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 300,0),
                child: Text("Services",style: GoogleFonts.manrope(fontSize: 21, color: Colors.black,fontWeight: FontWeight.bold),
               ),
              ),
              SizedBox(height: 20,),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 0, 8),
                    child: Row(
                      children: [
                        Servicecard(title: "Home Cleaning", image:'assets/images/service_home.png' ),
                        SizedBox(width: 15,),
                        Servicecard(title: "Laundry", image:'assets/images/service_laundry.png' ),
                        SizedBox(width: 15,),
                        Servicecard(title: "Mobile Carwash Service ", image:'assets/images/service_car.png' ),

                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20,),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 110, 0),
                child: Padding(
                  padding: const EdgeInsets.only(),
                  child: Text("Upcoming Appointments",style: GoogleFonts.manrope(fontSize: 21, color: Colors.black,fontWeight: FontWeight.bold), textAlign: TextAlign.start,
                  ),
                ),

              ),
              SizedBox(height: 20,),



            ],
          ),

        ),



      ),





    );

  }
}