import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class trackcard extends StatelessWidget {
  final String name;
  final String title;
  final int rating=0;
  final String service;

  const trackcard({super.key, required this.name, required this.title, required this.service});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text("$name - $title",style:GoogleFonts.manrope(fontWeight: FontWeight.normal),
            ),
            SizedBox(height: 3,),

          ],

        ),
        Text(rating.toString(),style: GoogleFonts.manrope(fontWeight: FontWeight.normal), textAlign: TextAlign.start,),
      ],
    );
  }
}
