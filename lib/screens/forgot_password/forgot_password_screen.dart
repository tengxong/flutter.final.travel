import 'package:app_travel/utils/keyboard.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart'; // Import GoogleFonts
import 'package:flutter/gestures.dart';
import 'package:app_travel/screens/login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSendingOtp = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isSendingOtp = true;
      _errorMessage = null;
    });

    try {
      String email = _emailController.text.trim();

      // ส่งลิงก์รีเซ็ตรหัสผ่านไปที่อีเมล
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('A password reset link has been sent to your email.', style: GoogleFonts.poppins())),
      );
      setState(() => _isSendingOtp = false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSendingOtp = false;
        _errorMessage = e.message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'An error occurred while sending reset email', style: GoogleFonts.poppins())),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSendingOtp = false;
        _errorMessage = 'An error occurred: ${e.toString()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: ${e.toString()}', style: GoogleFonts.poppins())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      child: Scaffold(
        body: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                'assets/images/background.jpeg', // Your background image
                fit: BoxFit.cover,
              ),
            ),
            // Dark Overlay
            Container(
              color: const Color.fromRGBO(0, 0, 0, 0.5), // Adjust opacity as needed
            ),
            // Content ScrollView
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 100),
                    Text(
                      'Forgot Password',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 50),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.poppins(color: Colors.black),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'Enter your email address',
                              hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                              labelStyle: GoogleFonts.poppins(color: Colors.grey[800]),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Colors.blueAccent),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                              suffixIcon: Icon(Icons.email, color: Colors.grey[600]),
                            ),
                            validator: MultiValidator([
                              RequiredValidator(errorText: 'Please enter your email'),
                              EmailValidator(errorText: 'Invalid email address'),
                            ]).call,
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _isSendingOtp ? null : _sendOtp,
                              icon: _isSendingOtp
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.send),
                              label: Text(
                                _isSendingOtp ? 'Sending...' : 'Send Reset Link',
                                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                            ),
                          ),
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.poppins(color: Colors.red, fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          const SizedBox(height: 20),
                          RichText(
                            text: TextSpan(
                              text: 'Remember your password? ',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Back to Login',
                                  style: GoogleFonts.poppins(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const LoginScreen(),
                                        ),
                                      );
                                    },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}