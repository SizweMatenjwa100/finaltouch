import 'package:finaltouch/main_navigation.dart';
import 'package:finaltouch/presentation/location/location_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../features/auth/logic/auth_bloc.dart';
import '../../../features/location/logic/authGate.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _registerUser() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    context.read<AuthBloc>().add(SignUpRequested(email: email, password: password));
  }

  Widget _buildTextField(
      TextEditingController controller, String hint,
      {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: 375,
        height: 56,
        child: TextFormField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xffE8F0F2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(String text) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        backgroundColor: const Color(0xFFE8F0F2),
        side: const BorderSide(color: Color(0xFFE8F0F2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(text, style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.bold, color: const Color(0xff4F8296), fontSize: 16)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AuthGate()),
            );
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error)),
            );
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            return SingleChildScrollView(
              child: Column(
                children: [
                  Image.asset('assets/images/Registerbanner.png'),
                  const SizedBox(height: 20),
                  Text("Join us and book your next ",
                      style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 24)),
                  const SizedBox(height: 2),
                  Text("clean in seconds!",
                      style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 24)),
                  const SizedBox(height: 20),

                  _buildTextField(_fullNameController, "Full name"),
                  _buildTextField(_emailController, "Email"),
                  _buildTextField(_phoneController, "Phone Number"),
                  _buildTextField(_passwordController, "Password", isPassword: true),
                  _buildTextField(_confirmPasswordController, "Confirm Password", isPassword: true),

                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: isLoading ? null : _registerUser,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFF1CABE3),
                          side: const BorderSide(color: Color(0xFF1CABE3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text("Register", style: GoogleFonts.plusJakartaSans(
                            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ),

                  Text("Already have an account? Log in",
                      style: GoogleFonts.manrope(fontSize: 14)),
                  const SizedBox(height: 15),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 0, 0),
                    child: Row(
                      children: [
                        _buildSocialButton("Google"),
                        const SizedBox(width: 10),
                        _buildSocialButton("Facebook"),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
