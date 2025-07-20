import 'package:finaltouch/payment_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

class Schedulemodule extends StatefulWidget {
  const Schedulemodule({super.key});

  @override
  State<Schedulemodule> createState() => _SchedulemoduleState();
}

class _SchedulemoduleState extends State<Schedulemodule> {
  DateTime _selectedDate=DateTime.now();
  String _selectedTime='';
  bool _sameCleaner =false;

  List<String> _timeSlots= ['8 AM - 10 AM', '10 AM - 12 PM', '2 PM - 4 PM'];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Schedule", style: GoogleFonts.manrope(),),
        leading: IconButton(onPressed: (){}, icon: Icon(Icons.arrow_back)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Pick a date and time", style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: TableCalendar(focusedDay: _selectedDate , firstDay: DateTime.utc(2025,1,1), lastDay: DateTime.utc(2025,12,12),
                  selectedDayPredicate: (day)=> isSameDay(day,_selectedDate),
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _selectedDate = selected;
                    });
                  },
                  calendarStyle: CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: Color(0xFF1CABE3),
                      shape: BoxShape.circle
                    ),
                    todayDecoration: BoxDecoration(
                      color: Color(0xFF5BC6EB),
                      shape: BoxShape.circle
                    )
                  ),
                ),
              ),
              SizedBox(height: 15,),
              DropdownButtonFormField(
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  hintText: "Select Time Slots",
                  hintStyle: GoogleFonts.manrope(),
        
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1.2
                    ),
        
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color:Colors.grey.shade300,
                      width: 1.5
                    )
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color:Colors.grey.shade300,
                      width: 1.5
                    )
                  )
        
        
        
                ),
                  value: _selectedTime.isEmpty? null:_selectedTime,
                  items:  _timeSlots.map((time)=>DropdownMenuItem(
                    value: time,
                      child: Text(time),
                  )
                  ).toList() ,
                  onChanged:(value){
                  setState(() {
                    _selectedTime=value!;
                  });
                  },
        
              ),
              SizedBox(height: 16,),
              Row(
                children: [
                  Text("Request Same Cleaner", style: GoogleFonts.manrope(fontSize: 16),),
                  SizedBox(width: 198,),
                  Switch(
                    activeColor: Color(0xFF1CABE3),
                      inactiveTrackColor: Colors.white,
                      inactiveThumbColor: Colors.black,
                      value: _sameCleaner, onChanged: (value){
                    setState(() {
                      _sameCleaner=value;
                    });
                  }
                  ),
        
                ],
              ),
              SizedBox(height: 20,),
              Text("Summary & Price Estimate",style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold),),
              SizedBox(height: 16,),
              Row(
                //mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text("Estimated Total",style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.normal),),
                  SizedBox(width: 260,),
                  Text("R450",style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold),)
                ],
              ),
              SizedBox(height: 190,),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(onPressed: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context)=>paymentScreen()
                    )
                  );
                },style: OutlinedButton.styleFrom(
                  backgroundColor: Color(0xFF1CABE3),
                  side: BorderSide( color:Color(0xFF1CABE3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                  child: Text("Continue to Payment", style:
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
