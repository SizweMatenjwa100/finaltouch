import 'package:finaltouch/features/location/logic/authGate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../features/auth/logic/auth_bloc.dart';
import '../../../main_navigation.dart';
import 'registerpage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _loginUser() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    context.read<AuthBloc>().add(LoginRequested(email: email, password: password));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthLoading) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator(
                  color: Color(0xFFE8F0F2),
                )),
              );
            } else if (state is AuthSuccess) {
              Navigator.of(context).pop(); // Remove loading
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthGate()));
            } else if (state is AuthFailure) {
              Navigator.of(context).pop(); // Remove loading
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error)));
            }
          },
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset('assets/images/Banner.png', fit: BoxFit.cover, width: double.infinity),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                  child: Text(
                    "Get your home, office, or car cleaned!",
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 21),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField(_emailController, "Email"),
                const SizedBox(height: 12),
                _buildTextField(_passwordController, "Password", isPassword: true),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 0, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Forgot your password?",
                        style: GoogleFonts.plusJakartaSans(color: const Color(0xff4F8296))),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 0, 0),
                  child: Row(
                    children: [
                      OutlinedButton(
                        onPressed: _loginUser,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFF1CABE3),
                          side: const BorderSide(color: Color(0xFF1CABE3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text("Login",
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()));
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFE8F0F2),
                          side: const BorderSide(color: Color(0xFFE8F0F2)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text("Register",
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold, color: const Color(0xff4F8296), fontSize: 16)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Text("Or log in with",
                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFF4F8296), fontSize: 14)),
                const SizedBox(height: 10),
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
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.92,
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
      child: Text(text,
          style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold, color: const Color(0xff4F8296), fontSize: 16)),
    );
  }
}
