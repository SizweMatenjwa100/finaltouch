import 'package:finaltouch/trackcard.dart';
import 'package:flutter/material.dart';

class Trackscreen extends StatefulWidget {
  const Trackscreen({super.key});

  @override
  State<Trackscreen> createState() => _TrackscreenState();
}

class _TrackscreenState extends State<Trackscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.arrow_back),
      ),
      body: Column(
        children: [
          trackcard(name:"Sizwe",title: "Team Lead", service: 'Home Cleaning',)
        ],
      ),
    );
  }
}
