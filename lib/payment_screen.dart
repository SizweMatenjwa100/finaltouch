import 'package:finaltouch/GooglePay&ApplePay.dart';
import 'package:finaltouch/buildCardTile.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class paymentScreen extends StatelessWidget {
  const paymentScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: Icon(Icons.arrow_back),
        title: Text("Payment methods",style: GoogleFonts.manrope( fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
     body: Padding(
       padding: const EdgeInsets.all(16.0),
       child: ListView(
         children: [
           Text("Your cards", style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 16),),
           SizedBox(height: 20,),

           buildCard(cardType: "Visa", CardNumber: "Visa ***** 0008", CardImage:"assets/images/Visa_2021.png", expire: "Expires 03/2026", ),
           SizedBox(height: 15,),
           buildCard(cardType: "Visa", CardNumber: "Mastercard ***** 0008", CardImage:"assets/images/mastercard-logo.png", expire: "Expires 06/2025", ),
           SizedBox(height: 20,),
           ContactlessPay(applePayLogo: "assets/images/Apple_Pay-Logo.png", googlePayLogo: null,title: "Apple Pay",),
           SizedBox(height: 20,),
           Row(
             children: [
               Container(

                 height: 35,
                 width: 55,
                 child: OutlinedButton(onPressed: (){},
                   style: OutlinedButton.styleFrom(
                     backgroundColor: Colors.grey[200],
                     side: BorderSide(

                       color:Colors.white
                     ),
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(10)
                     ),
                     padding: EdgeInsets.zero, // remove default padding
                     alignment: Alignment.center,
                   

                   ),
                     child: Center(
                         child: Icon(Icons.add, color: Colors.black,size: 30,)
                     )
                     ),
               ),
               SizedBox(width:20,),
               Text("Add payment method",style:GoogleFonts.manrope(
                   fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black
               ),
               ),

             ],
           ),
           SizedBox(height: 460,),

           OutlinedButton(onPressed: (){

           },style:
           OutlinedButton.styleFrom(

               backgroundColor: Color(0xFF1CABE3),
               side: BorderSide( color:Color(0xFF1CABE3)),
               shape: RoundedRectangleBorder(
                 borderRadius: BorderRadius.circular(12),
               )
           ),
             child: Text("Proceed to Payment",style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold,color:Colors.white, fontSize: 16),),
           ),


         ],

       ),
     ),
    );
  }
}
