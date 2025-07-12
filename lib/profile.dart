import 'package:finaltouch/Package_card.dart';
import 'package:finaltouch/profileinformation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Profilescreen extends StatelessWidget {
  const Profilescreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: Icon(Icons.arrow_back),
        title: Text("Profile",style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 20),),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
        
            Profileinformation(image:"assets/images/profileimage.png", email: "olivia.bennett@email.com", name: "Olivia Bennett"),
            SizedBox(height: 20,),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 20, 160, 0),
              child: Text("Account Details", style:GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
            ),
            SizedBox(height: 20,),
            PackageCard(name: "Personal information", description: "Manage your personal information", image: "assets/images/profileavatar.png"),
            SizedBox(height: 20 ,),
            PackageCard(name: "Booking History", description: "View your past bookings", image: 'assets/images/Bookingavatar.png'),
            SizedBox(height: 10,),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: OutlinedButton(onPressed: (){},style: OutlinedButton.styleFrom(backgroundColor: Color(0xffF1F3F4),
                side: BorderSide(color:Color(0xFFF1F3F4))

              ),
                  child: SizedBox(
                    width: double.infinity,
                      child: Text("Log Out",style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color:Colors.black),textAlign: TextAlign.center,)
                  ),
              ),
            )
        
          ],
        
        ),
      ),

    );
  }
}
