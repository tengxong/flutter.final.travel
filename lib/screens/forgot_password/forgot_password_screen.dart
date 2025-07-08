// lib/screens/forgot_password_screen.dart (หรือไฟล์ที่คุณสร้าง)
import 'package:app_travel/utils/keyboard.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'dart:async';
import 'package:app_travel/screens/forgot_password/otp_verify_screen.dart';
import 'package:google_fonts/google_fonts.dart'; // Import GoogleFonts
import 'package:flutter/gestures.dart';
import 'package:app_travel/screens/login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String _phoneNumber = '';

  bool _isSendingOtp = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // _phoneController.text = '+66'; // ลบการตั้งค่าเริ่มต้นออก
    // _phoneController.selection = TextSelection.fromPosition(
    //   TextPosition(offset: _phoneController.text.length),
    // );
  }

  @override
  void dispose() {
    _phoneController.dispose();
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
      // ลบโค้ดเติมรหัสประเทศอัตโนมัติออก เพราะ validator บังคับให้กรอกแบบ E.164 แล้ว
      String finalPhoneNumber = _phoneNumber.trim();
      // if (!finalPhoneNumber.startsWith('+')) {
      //   finalPhoneNumber = '+66$finalPhoneNumber'; 
      // }

      // For phone number lookup, the design doesn't show a country code picker.
      // Assuming _phoneNumber is already in the full international format (e.g., +66xxxxxxxxxx)
      // If not, you might need to add a way to get the country code here or modify Firestore logic.
      QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('phone', isEqualTo: finalPhoneNumber) // ใช้ finalPhoneNumber สำหรับการค้นหา
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่พบเบอร์โทรศัพท์นี้ในระบบ', style: GoogleFonts.poppins())),
        );
        setState(() => _isSendingOtp = false);
        return;
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: finalPhoneNumber, // ใช้ finalPhoneNumber สำหรับ Firebase Auth
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ยืนยันรหัส OTP อัตโนมัติสำเร็จ! กำลังนำทาง...', style: GoogleFonts.poppins())),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerifyScreen(
                phoneNumber: finalPhoneNumber,
                verificationId: credential.verificationId!,
                autoSmsCode: credential.smsCode,
                onResendOtp: _sendOtp,
              ),
            ),
          );
          setState(() {
            _isSendingOtp = false;
          });
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          setState(() {
            _isSendingOtp = false;
            _errorMessage = 'ยืนยันเบอร์โทรศัพท์ล้มเหลว: ${e.message}';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_errorMessage!, style: GoogleFonts.poppins())),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          setState(() {
            _isSendingOtp = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ส่งรหัส OTP แล้ว! กรุณากรอกรหัส', style: GoogleFonts.poppins())),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerifyScreen(
                phoneNumber: finalPhoneNumber,
                verificationId: verificationId,
                onResendOtp: _sendOtp,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (!mounted) return;
          setState(() {
            _isSendingOtp = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('หมดเวลาการดึงรหัส OTP อัตโนมัติ', style: GoogleFonts.poppins())),
          );
        },
        timeout: const Duration(seconds: 60),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSendingOtp = false;
        _errorMessage = e.message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'เกิดข้อผิดพลาดในการส่งรหัส OTP', style: GoogleFonts.poppins())),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSendingOtp = false;
        _errorMessage = 'เกิดข้อผิดพลาด: ${e.toString()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: ${e.toString()}', style: GoogleFonts.poppins())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      child: Scaffold(
        // Removed AppBar
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
                padding: const EdgeInsets.symmetric(horizontal: 28.0), // Consistent padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Align to left for title
                  children: [
                    const SizedBox(height: 100), // Spacing from top
                    Text(
                      'Forgot Password',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 50), // Spacing between title and form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: GoogleFonts.poppins(color: Colors.black),
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              hintText: 'Enter your phone number (e.g., +66XXXXXXXXX)',
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
                              suffixIcon: Icon(Icons.phone, color: Colors.grey[600]), // Icon at the end
                            ),
                            validator: MultiValidator([
                              RequiredValidator(errorText: 'Please enter your phone number'),
                              PatternValidator(r'^\+[1-9]\d{7,14}$', errorText: 'Invalid phone number (must be in E.164 format, e.g., +66XXXXXXXXX)'),
                            ]).call,
                            onChanged: (v) => _phoneNumber = v,
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
                                  : const Icon(Icons.send), // Send icon
                              label: Text(
                                _isSendingOtp ? 'Sending...' : 'Send',
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