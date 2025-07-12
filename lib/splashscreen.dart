import 'dart:async';
import 'package:finaltouch/onboarding.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:finaltouch/presentation/auth/pages/loginscreen.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
  @override
  void initState() {
    super.initState();

    // Navigate to LoginScreen after 3 seconds
    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const onBoarding1()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/splash.png', fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 280, 10, 10),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(52, 0, 0, 0),
                  child: Row(
                    children: [
                      Text(
                        "Final Touch",
                        style: GoogleFonts.leagueSpartan(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontSize: 51,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        ".",
                        style: GoogleFonts.leagueSpartan(
                          fontSize: 51,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xff1CABE3),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  "B e y o n d  C l e a n  -  I t' s  T h e  F i n a l  T o u c h",
                  style: GoogleFonts.quicksand(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 90),
                Text(
                  "S i n c e",
                  style: GoogleFonts.quicksand(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
                Text(
                  "2 0 2 0",
                  style: GoogleFonts.quicksand(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
