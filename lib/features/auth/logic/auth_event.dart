part of 'auth_bloc.dart';

abstract class AuthEvent{}

class SignUpRequested extends AuthEvent{
  final String email;
  final String password;
  SignUpRequested({required this.email, required this.password});
}
