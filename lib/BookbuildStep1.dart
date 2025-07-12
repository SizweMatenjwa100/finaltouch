import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WidgetStep extends StatefulWidget {
  const WidgetStep({super.key});

  @override
  State<WidgetStep> createState() => _WidgetStepState();
}

class _WidgetStepState extends State<WidgetStep> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Step 1: Property Info", style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20,),
       DropdownButtonFormField(
         decoration: InputDecoration(
           contentPadding:  EdgeInsets.symmetric(horizontal: 16, vertical: 4),

           fillColor: Colors.white,

           filled: true,
           hintText: "Select Property Type",
           hintStyle: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: Colors.black),

           border:OutlineInputBorder(
             borderRadius: BorderRadius.circular(10),
             borderSide: BorderSide(
               color:Colors.grey.shade300,
               width: 1.2
             ),
           ),

           enabledBorder: OutlineInputBorder(
             borderRadius: BorderRadius.circular(10),
             borderSide: BorderSide(
               color:Colors.grey.shade300,
               width: 1.2
             ),

           ),
           focusedBorder: OutlineInputBorder(
             borderRadius: BorderRadius.circular(10),
             borderSide: BorderSide(
               color: Colors.grey.shade300,
               width: 1.5
             )
           )
         ),
         items: ['Apartment', 'House'].map((e) =>
             DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.manrope(),
              ),
             ),
         ).toList(),
         onChanged: (val) {},
       ),
        SizedBox(height: 8,),
        DropdownButtonFormField(
          decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),

              fillColor: Colors.white,

              filled: true,
              hintText: "Select Bedrooms",
              hintStyle: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: Colors.black),

              border:OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color:Colors.grey.shade300,
                    width: 1.2
                ),
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color:Colors.grey.shade300,
                    width: 1.2
                ),

              ),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1.5
                  )
              )
          ),
          items: ['1', '2','3','4','5','6'].map((e) =>
              DropdownMenuItem(value: e,  child: Text(e, style: GoogleFonts.manrope(),
              ),
              ),
          ).toList(),
          onChanged: (val) {},
        ),
        SizedBox(height: 8,),
        DropdownButtonFormField(

          decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),

              fillColor: Colors.white,

              filled: true,
              hintText: "Select Bathrooms",
              hintStyle: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: Colors.black),

              border:OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color:Colors.grey.shade300,
                    width: 1.2
                ),
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color:Colors.grey.shade300,
                    width: 1.2
                ),

              ),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1.5
                  )
              )
          ),
          items: ['1', '2','3','4','5','6'].map((e) =>
              DropdownMenuItem(value: e,  child: Text(e, style: GoogleFonts.manrope(),
              ),
              ),
          ).toList(),
          onChanged: (val) {},
        ),

      ],
    );
  }
}
