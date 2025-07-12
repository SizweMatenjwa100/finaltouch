import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'onBoarding4.dart';

class onBoarding3 extends StatefulWidget {
  const onBoarding3({super.key});

  @override
  State<onBoarding3> createState() => _onBoarding3State();
}

class _onBoarding3State extends State<onBoarding3> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Image.asset('assets/images/onBoarding3.png', fit: BoxFit.cover),
          const SizedBox(height: 20),
          Text(
            "Secure & Easy Payments",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            "Pay safely and easily within the app",
            style: GoogleFonts.plusJakartaSans(fontSize: 15),
          ),
          const SizedBox(height: 370),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 300),
                      pageBuilder: (context, animation, secondaryAnimation) =>
                      const onBoarding4(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        const begin = Offset(1.0, 0.0); // Slide from right
                        const end = Offset.zero;
                        const curve = Curves.easeInOut;

                        final tween = Tween(begin: begin, end: end)
                            .chain(CurveTween(curve: curve));

                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFF1CABE3),
                  side: const BorderSide(color: Color(0xFF1CABE3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Next",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
