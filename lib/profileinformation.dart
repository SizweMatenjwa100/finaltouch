import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class Profileinformation extends StatelessWidget {
  final String image;
  final String email;
  final String name;
  const Profileinformation({super.key, required this.image, required this.email, required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(90, 0, 90, 0 ),
      child: Column(
        children: [
          SizedBox(
            height: 128,
              width: 128,
              child: Image.asset(image)
          ),
          SizedBox(height: 20,),
          Text(name, style:GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(email, style:GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.normal))
        ],

      ),
    );

  }
}
