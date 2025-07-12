import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Bookbuildstep2 extends StatefulWidget {
  const Bookbuildstep2({super.key});

  @override
  State<Bookbuildstep2> createState() => _Bookbuildstep2State();
}

class _Bookbuildstep2State extends State<Bookbuildstep2> {
  String _selected ='Basic';
  final List<String> _options=[
    'Basic',
    'Standard',
    'Premium',
    'Move In/Out'

  ];
  @override
  Widget build(BuildContext context) {
    return Column(
     crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text("Step 2: Cleaning Type", style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20,),
        ..._options.map((option)=>Padding(padding: EdgeInsets.only(bottom: 12),
          child:
          RadioListTile(
              value: option, groupValue: _selected, onChanged:(value){
                setState(() {
                  _selected=value!;
                });
          },
            title: Text(option,style: GoogleFonts.manrope(fontSize: 16 ),),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side:BorderSide(
                color: Colors.grey.shade300,
                width: 1.2
              ),
            ),
            controlAffinity: ListTileControlAffinity.trailing,
            tileColor: Colors.white,
            activeColor: Color(0xFF1CABE3),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
        ),

        ),
        SizedBox(height: 20,),

      ],

    );
  }
}
