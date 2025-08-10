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
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _agreeToTerms = false;

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
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please accept the terms and conditions")),
      );
      return;
    }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthLoading) {
            setState(() => _isLoading = true);
          } else if (state is AuthSuccess) {
            setState(() => _isLoading = false);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AuthGate()),
            );
          } else if (state is AuthFailure) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(child: Text(state.error)),
                  ],
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Header Image
                  Container(
                    height: MediaQuery.of(context).size.height * 0.2,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/Registerbanner.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Welcome Text
                  Text(
                    "Create Account",
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Join us and book your next clean in seconds!",
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // Form Fields
                  _buildTextField(
                    controller: _fullNameController,
                    label: "Full Name",
                    hint: "Enter your full name",
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Full name is required";
                      }
                      if (value.trim().length < 2) {
                        return "Name must be at least 2 characters";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  _buildTextField(
                    controller: _emailController,
                    label: "Email Address",
                    hint: "Enter your email",
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Email is required";
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                        return "Please enter a valid email";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  _buildTextField(
                    controller: _phoneController,
                    label: "Phone Number",
                    hint: "Enter your phone number",
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        if (!RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(value.trim())) {
                          return "Please enter a valid phone number";
                        }
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  _buildTextField(
                    controller: _passwordController,
                    label: "Password",
                    hint: "Create a password",
                    icon: Icons.lock_outline,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Password is required";
                      }
                      if (value.trim().length < 6) {
                        return "Password must be at least 6 characters";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  _buildTextField(
                    controller: _confirmPasswordController,
                    label: "Confirm Password",
                    hint: "Confirm your password",
                    icon: Icons.lock_outline,
                    isPassword: true,
                    isConfirmPassword: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Please confirm your password";
                      }
                      if (value.trim() != _passwordController.text.trim()) {
                        return "Passwords do not match";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Terms and Conditions
                  Row(
                    children: [
                      Checkbox(
                        value: _agreeToTerms,
                        onChanged: (value) {
                          setState(() {
                            _agreeToTerms = value ?? false;
                          });
                        },
                        activeColor: const Color(0xFF1CABE3),
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            children: [
                              const TextSpan(text: "I agree to the "),
                              TextSpan(
                                text: "Terms of Service",
                                style: GoogleFonts.manrope(
                                  color: const Color(0xFF1CABE3),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const TextSpan(text: " and "),
                              TextSpan(
                                text: "Privacy Policy",
                                style: GoogleFonts.manrope(
                                  color: const Color(0xFF1CABE3),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Register Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _registerUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1CABE3),
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Creating account...",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                          : Text(
                        "Create Account",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "or sign up with",
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Social Register Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildSocialButton(
                          "Google",
                          Icons.g_mobiledata,
                              () {},
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSocialButton(
                          "Facebook",
                          Icons.facebook,
                              () {},
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Sign In",
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF1CABE3),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isConfirmPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword
              ? (isConfirmPassword ? _obscureConfirmPassword : _obscurePassword)
              : false,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.manrope(fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.manrope(
              color: Colors.grey.shade500,
            ),
            prefixIcon: Icon(icon, color: const Color(0xFF1CABE3)),
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(
                (isConfirmPassword ? _obscureConfirmPassword : _obscurePassword)
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.grey.shade600,
              ),
              onPressed: () {
                setState(() {
                  if (isConfirmPassword) {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  } else {
                    _obscurePassword = !_obscurePassword;
                  }
                });
              },
            )
                : null,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1CABE3), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(String text, IconData icon, VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.grey.shade700),
      label: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
          fontSize: 14,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}