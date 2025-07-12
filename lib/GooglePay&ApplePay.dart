import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ContactlessPay extends StatelessWidget {
  String? applePayLogo;
  String? googlePayLogo;
  String title;
 ContactlessPay({super.key, required this.applePayLogo, required this.googlePayLogo, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 25,
          width: 55,
          decoration: BoxDecoration(
            border: Border.all(
              width: 1.6
            ),
            borderRadius: BorderRadius.circular(4),

          ),
          child: Expanded(
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 9.0),
                  child: Image.asset(applePayLogo!, alignment: Alignment.center,height: 25,),
                ),
            
              ],
            ),
          ),

        ),
        SizedBox(width: 20),
        Text("Apple Pay",style:GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black),

    )
      ],

    );

  }
}
