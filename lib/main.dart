// lib/main.dart - UPDATED WITH PAYMENT INTEGRATION
import 'package:finaltouch/features/location/logic/authGate.dart';
import 'package:finaltouch/presentation/auth/pages/loginscreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

// AUTH
import 'features/auth/data/repositories/auth_respository.dart';
import 'features/auth/logic/auth_bloc.dart';
import 'presentation/auth/pages/registerpage.dart';

// LOCATION
import 'features/location/data/repositories/location_repository.dart';
import 'features/location/logic/locationBloc.dart';
import 'features/location/logic/locationEvent.dart';

// BOOKING
import 'features/booking/data/booking_Repository.dart';
import 'features/booking/logic/booking_bloc.dart';

// PAYMENT - NEW
import 'features/payment/data/payment_repository.dart';
import 'features/payment/logic/payment_bloc.dart';

// APP
import 'main_navigation.dart';
import 'splashscreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    return MultiBlocProvider(
      providers: [
        // AUTH BLOC
        BlocProvider(
          create: (_) => AuthBloc(
            authRepository: AuthRepository(),
          ),
        ),

        // LOCATION BLOC
        BlocProvider(
          create: (_) => LocationBloc(
            locationRepository: LocationRepository(
              firestore: firestore,
              auth: auth,
            ),
          )..add(CheckLocationEvent()),
        ),

        // BOOKING BLOC
        BlocProvider(
          create: (_) => BookingBloc(
            bookingRepository: BookingRepository(
              firestore: firestore,
              auth: auth,
            ),
          ),
        ),

        // PAYMENT BLOC - NEW
        BlocProvider(
          create: (_) => PaymentBloc(
            paymentRepository: PaymentRepository(
              firestore: firestore,
              auth: auth,
            ),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Final Touch',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: const Color(0xFF1CABE3),
          fontFamily: 'Manrope',
        ),
        home: const Splashscreen(),
      ),
    );
  }
}