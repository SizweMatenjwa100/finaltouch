import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Searchscreen extends StatefulWidget {
  const Searchscreen({super.key});

  @override
  State<Searchscreen> createState() => _SearchscreenState();
}

class _SearchscreenState extends State<Searchscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: Icon(Icons.arrow_back),
        title: Text("Search", style: GoogleFonts.manrope(fontWeight: FontWeight.bold),),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 5, 16, 0),
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              color:  Color(0xFFF1F3F4),
              borderRadius: BorderRadius.circular(16),
          
            ),
            child:TextField(
              cursorColor: Colors.black,
              style: GoogleFonts.manrope(),
              decoration: InputDecoration(
                hintText: "Search services, packages, cleaner...",
                hintStyle: GoogleFonts.manrope(
                  color:Colors.grey[600]
                ),
                border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  //suffixIcon: Icon(Icons.clear, color: Colors.grey[600]),
              ),
            ),
          
          ),
        ),
      )
    );
  }
}