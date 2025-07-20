import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../main_navigation.dart';
import '../../../presentation/location/location_screen.dart';
import '../data/repositories/location_repository.dart';
import 'locationBloc.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<bool> _checkIfUserHasLocation() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return false;

    final locationSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('locations')
        .limit(1)
        .get();

    return locationSnapshot.docs.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkIfUserHasLocation(),
      builder: (context, snapshot) {
        // Loading UI
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Error UI
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text("Error: ${snapshot.error}")),
          );
        }

        final bool hasLocation = snapshot.data ?? false;

        // Provide LocationBloc globally here
        return BlocProvider(
          create: (_) => LocationBloc(
            locationRepository: LocationRepository(
              firestore: FirebaseFirestore.instance,
              auth: FirebaseAuth.instance,
            ),
          ),
          child: hasLocation
              ? const MainNavigation()
              : const SelectLocationScreen(),
        );
      },
    );
  }
}
