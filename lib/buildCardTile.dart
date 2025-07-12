import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

class buildCard extends StatelessWidget {
  String cardType;
  String CardNumber;
  String CardImage;
  String expire;

  buildCard({super.key, required this.cardType, required this.CardNumber, required this.CardImage, required this.expire});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 25,
          decoration: BoxDecoration(
            color:Color(0xFFFFFF),
            border: Border.all(
              width:1,
              color: Color(0xFFC6C6C6)
            ),


            borderRadius: BorderRadius.circular(4),

          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(6.0),
                child: Image.asset(CardImage, width: 40,height: 30,
                fit: BoxFit.cover,),


              ),
              SizedBox(height: 10,),

            ],
          ),


          ),
        SizedBox(width: 20,),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(CardNumber,style:GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black),

            ),
            SizedBox(height: 2,),
            Text(expire,style:GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.normal, color: Colors.grey),textAlign: TextAlign.start,

            ),

          ],
        ),
       Spacer(),
        IconButton(onPressed: (){}, icon: Icon(Icons.delete_outline ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: Colors.white,
              width: 0
            ),
          ),
        )
      ],

    );
  }
}
