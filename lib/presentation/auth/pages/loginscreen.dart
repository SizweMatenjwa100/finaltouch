import 'dart:ffi';

import 'package:finaltouch/homepage.dart';
import 'package:finaltouch/main_navigation.dart';
import 'package:finaltouch/presentation/auth/pages/registerpage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child:
      SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('assets/images/Banner.png', fit:BoxFit.cover, width: double.infinity,),
            SizedBox(height: 30,),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
              child: Text("Get your home, office, or car cleaned!",
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold,fontSize: 21),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 20,),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.92,
                height: 56,
                child: TextFormField(
                  decoration: InputDecoration(
                    hintText: "Email",
                    filled: true,
                    fillColor: Color(0xffE8F0F2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none
                    )
                  ),

                ),
              ),

            ),
            SizedBox(height: 12,),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.92,
                height: 56,
                child: TextFormField(
                  decoration: InputDecoration(
                      hintText: "Password",
                      filled: true,
                      fillColor: Color(0xffE8F0F2),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none
                      )
                  ),

                ),
              ),

            ),
            SizedBox(height: 5,),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 0, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text("Forgot your password?", textAlign: TextAlign.start,style: GoogleFonts.plusJakartaSans(color:Color(0xff4F8296)),),
                ],
              ),
            ),
            SizedBox(height: 20,),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 0, 0),
              child: Row(
                children: [
                  OutlinedButton(onPressed: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>MainNavigation()));
                  },style: OutlinedButton.styleFrom(
                    backgroundColor: Color(0xFF1CABE3),
                    side: BorderSide( color:Color(0xFF1CABE3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                    child: Text("Login", style:
                  GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),

                  ),

                  ),
                  SizedBox(width: 10,),
                  OutlinedButton(onPressed: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>RegisterPage()));
                  },style:
                  OutlinedButton.styleFrom(

                    side: BorderSide(color:Color(0xFFE8F0F2)),
                    backgroundColor: Color(0xFFE8F0F2),
                    shape:RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)
                    )
                  ),
                      child: Text("Register",style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold,color:Color(0xff4F8296), fontSize: 16),),
                  ),


                ],
              ),


            ),
            SizedBox(height: 15,),
            Text("Or log in with",style: GoogleFonts.plusJakartaSans(color:Color(0xFF4F8296), fontSize: 14),
            ),
            SizedBox(height: 10,),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 0, 0),
              child: Row(
                children: [
                  OutlinedButton(onPressed: (){},style:
                  OutlinedButton.styleFrom(

                      side: BorderSide(color:Color(0xFFE8F0F2)),
                      backgroundColor: Color(0xFFE8F0F2),
                      shape:RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)
                      )
                  ),
                    child: Text("Google",style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold,color:Color(0xff4F8296), fontSize: 16),),
                  ),
                  SizedBox(width: 10,),
                  OutlinedButton(onPressed: (){},style:
                  OutlinedButton.styleFrom(

                      side: BorderSide(color:Color(0xFFE8F0F2)),
                      backgroundColor: Color(0xFFE8F0F2),
                      shape:RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)
                      )
                  ),
                    child: Text("Facebook",style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold,color:Color(0xff4F8296), fontSize: 16),),
                  ),

                ],
              ),
            )



          ],
        ),
      )
      ),
    );
  }
}
