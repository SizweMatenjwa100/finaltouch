import 'package:finaltouch/AddOns.dart';
import 'package:finaltouch/BookbuildStep1.dart';
import 'package:finaltouch/BookbuildStep2.dart';
import 'package:finaltouch/schedulemodule.dart';
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
        title: Text("Book Cleaning"),
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
              Schedulemodule()



            ],
          ),
        ),
      ),
    );
  }
}
