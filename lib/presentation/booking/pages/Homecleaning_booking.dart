import 'package:finaltouch/presentation/booking/widgets/AddOns.dart';
import 'package:finaltouch/presentation/booking/widgets/BookbuildStep1.dart';
import 'package:finaltouch/presentation/booking/widgets/BookbuildStep2.dart';
import 'package:finaltouch/presentation/booking/pages/schedulemodule.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomecleaningBooking extends StatelessWidget {
  const HomecleaningBooking({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(leading: Icon(Icons.arrow_back),
        backgroundColor: Colors.white,
        title: Text("Book a cleaning"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WidgetStep(),
              SizedBox(height: 20,),
              Bookbuildstep2(),
              Addons(),
              SizedBox(height: 15,),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(onPressed: (){
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context)=>Schedulemodule()
                      )
                  );
                },style: OutlinedButton.styleFrom(
                  backgroundColor: Color(0xFF1CABE3),
                  side: BorderSide( color:Color(0xFF1CABE3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                  child: Text("Continue", style:
                  GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),

                  ),

                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
