import 'package:finaltouch/main_navigation.dart';
import 'package:finaltouch/presentation/auth/pages/registerpage.dart';
import 'package:finaltouch/splashscreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/auth/data/repositories/auth_respository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'features/auth/data/repositories/auth_respository.dart';
import 'features/auth/logic/auth_bloc.dart';
import 'package:finaltouch/firebase_options.dart';



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
    return BlocProvider(
      create: (_) => AuthBloc(authRepository: AuthRepository()),
      child: MaterialApp(
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        home: MainNavigation() // or RegisterPage()
      ),
    );
  }
}
