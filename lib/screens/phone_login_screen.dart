import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:app_travel/services/auth_service.dart';
import 'package:app_travel/screens/otp_code_screen.dart';
import 'package:logger/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';

final Map<String, String> countryDialCodes = {
  'laos': '+856',
  'thailand': '+66',
  'vietnam': '+84',
};

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  final Logger _logger = Logger();
  String selectedCountry = 'laos'; // default

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String formatPhoneNumber(String phone, String countryCode) {
    phone = phone.replaceAll(RegExp(r'\s+|-'), '');
    if (phone.startsWith('0')) {
      phone = phone.substring(1);
    }
    return '$countryCode$phone';
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      String rawPhone = _phoneController.text.trim();
      String countryCode = countryDialCodes[selectedCountry] ?? '+856';
      String formattedPhone = formatPhoneNumber(rawPhone, countryCode);
      _logger.d('Sending phone number to Firebase: $formattedPhone');
      await authService.sendOTP(
        phoneNumber: formattedPhone,
        onCodeSent: (String verificationId) {
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => OtpCodeScreen(
                  phoneNumber: formattedPhone,
                  verificationId: verificationId,
                  onVerify: (otp) async {
                    await authService.verifyOTPAndSignIn(
                      verificationId: verificationId,
                      smsCode: otp,
                    );
                  },
                  onResend: () async {
                    await authService.sendOTP(
                      phoneNumber: formattedPhone,
                      onCodeSent: (_) {},
                      onError: (_) {},
                    );
                  },
                  title: 'Verify Phone Number',
                  subtitle: 'Please enter the 6-digit code sent to\n$formattedPhone',
                  successMessage: 'Login successful!',
                  onSuccess: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
              ),
            );
          }
        },
        onError: (String error) {
          setState(() {
            _errorMessage = error;
          });
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String? getCountryLabel(String phone) {
    if (phone.startsWith('+66') || (phone.startsWith('0') && phone.length == 10)) {
      return 'Thailand';
    } else if (phone.startsWith('+856') || phone.startsWith('020')) {
      return 'Laos';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.jpeg',
              fit: BoxFit.cover,
            ),
          ),
          // Dark Overlay
          Container(
            color: const Color.fromRGBO(0, 0, 0, 0.5),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Title
                  Text(
                    'Login with phone number',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Subtitle
                  Text(
                    'Please enter your phone number to receive the verification code',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Phone Number Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: DropdownButtonFormField<String>(
                            value: selectedCountry,
                            decoration: const InputDecoration(
                              labelText: 'Country',
                              border: OutlineInputBorder(),
                            ),
                            items: countryDialCodes.keys.map((country) {
                              return DropdownMenuItem(
                                value: country,
                                child: Text(country[0].toUpperCase() + country.substring(1)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedCountry = value!;
                              });
                            },
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Phone number',
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.grey[600],
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your phone number';
                              }
                              if (value.length < 9) {
                                return 'Phone number must be at least 9 digits';
                              }
                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        if (getCountryLabel(_phoneController.text) != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              getCountryLabel(_phoneController.text)!,
                              style: GoogleFonts.poppins(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        
                        // Error Message
                        if (_errorMessage != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.poppins(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        
                        const SizedBox(height: 24),
                        
                        // Send OTP Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _sendOTP,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Send verification code',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
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
    );
  }
}