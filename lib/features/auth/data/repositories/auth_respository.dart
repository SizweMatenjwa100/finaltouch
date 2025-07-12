import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository{

  final FirebaseAuth _firebaseAuth =FirebaseAuth.instance;
  Future<void> SignUp({
    required String email,
    required String password,
}) async {
    await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password
    );
  }
}