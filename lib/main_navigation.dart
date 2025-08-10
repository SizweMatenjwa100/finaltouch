// lib/main_navigation.dart - UPDATED WITH NEW PROFILE SCREEN
import 'dart:developer';

import 'package:finaltouch/Searchscreen.dart';
import 'package:finaltouch/mainBooking.dart';
import 'package:finaltouch/presentation/profile/pages/profile_screen.dart';
import 'package:finaltouch/presentation/trackBooking/trackscreen.dart';
import 'package:flutter/material.dart';
import 'homepage.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _selectedIndex = 0;
  final List<Widget> _screens = [
    Homepage(),
    Searchscreen(),
    MainBooking(),
    EnhancedTrackingScreen(),
    ProfileScreen(), // Updated to use the new ProfileScreen
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF1CABE3),
        unselectedItemColor: Colors.black,
        showUnselectedLabels: true,
        elevation: 6,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: "Home"
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: "Services"
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              label: "Schedule"
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.location_pin),
              label: "Track"
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: "Profile"
          ),
        ],
      ),
    );
  }
}