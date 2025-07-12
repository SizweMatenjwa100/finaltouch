import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class Servicecard extends StatelessWidget {
  final String title;
  final String image;

  const Servicecard({super.key, required this.title, required this.image});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 135,
            width: 235,
            child: Image.asset(image,fit:BoxFit.cover)
        ),
        SizedBox(height: 20,),
        Text(title,style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w400),
        ),
      ],

    );
  }
}
