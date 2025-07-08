import 'package:app_travel/utils/keyboard.dart';
import 'package:app_travel/model/login_view_model.dart';
import 'package:app_travel/screens/forgot_password/forgot_password_screen.dart';
import 'package:app_travel/screens/register_screen.dart';
import 'package:app_travel/screens/phone_login_screen.dart';
// import 'package:app_travel/services/auth_service.dart'; // ไม่ได้ใช้ตรงๆ ในนี้แล้ว
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // สำหรับ FirebaseAuthException types
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart'; // จำเป็นสำหรับ Provider // LoginViewModel ของคุณ
import 'package:google_fonts/google_fonts.dart';
import 'package:app_travel/screens/main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();

  // ไม่ต้องใช้ 'late' แล้ว
  // จะถูกกำหนดค่าใน initState ทันที
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _obscureText = true; // Added for password visibility toggle

  @override
  void initState() {
    super.initState();
    // เข้าถึง LoginViewModel ใน initState โดยใช้ listen: false
    // เพื่อดึงค่าเริ่มต้นที่ ViewModel โหลดมาจาก SharedPreferences
    final loginViewModel = Provider.of<LoginViewModel>(context, listen: false);

    // กำหนดค่าเริ่มต้นให้กับ TextEditingController ทันที
    _emailController = TextEditingController(text: loginViewModel.email);
    _passwordController = TextEditingController(text: loginViewModel.password);
  }

  @override
  void dispose() {
    // อย่าลืม dispose controllers เพื่อป้องกัน memory leak
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ฟังการเปลี่ยนแปลงของ LoginViewModel
    final loginViewModel = Provider.of<LoginViewModel>(context);

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
                padding: const EdgeInsets.symmetric(horizontal: 28.0), // Consistent padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Align to left for title
                  children: [
                    const SizedBox(height: 100), // Spacing from top
                    Text(
                      'Login',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 50), // Spacing between title and form
                    Form(
                      key: formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.poppins(color: Colors.black),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'Enter your email',
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
                              suffixIcon: Icon(Icons.email, color: Colors.grey[600]), // Icon at the end
                            ),
                            validator: MultiValidator([
                              RequiredValidator(errorText: 'Please enter your email'),
                              EmailValidator(errorText: 'Invalid email format'),
                            ]).call,
                            onChanged: (value) {
                              loginViewModel.setEmail(value);
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscureText,
                            style: GoogleFonts.poppins(color: Colors.black),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter your password',
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
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureText ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey[600],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureText = !_obscureText;
                                  });
                                },
                              ),
                            ),
                            validator: RequiredValidator(
                              errorText: 'Please enter your password',
                            ).call,
                            onChanged: (value) {
                              loginViewModel.setPassword(value);
                            },
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Forgot password ?',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16), // Reduced space after forgot password
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30), // More rounded
                                ),
                                backgroundColor: Colors.orange, // Orange button
                                foregroundColor: Colors.white,
                              ),
                              onPressed: loginViewModel.isLoading
                                  ? null
                                  : () async {
                                      if (formKey.currentState!.validate()) {
                                        final messenger = ScaffoldMessenger.of(context);
                                        final navigator = Navigator.of(context);

                                        try {
                                          bool success = await loginViewModel.signInUser();

                                          if (success) {
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text('Login successful', style: GoogleFonts.poppins()),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                            navigator.pushReplacement(
                                              MaterialPageRoute(
                                                builder: (context) => const MainScreen(),
                                              ),
                                            );
                                          } else {
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  loginViewModel.errorMessage ?? 'An error occurred',
                                                  style: GoogleFonts.poppins(),
                                                ),
                                                backgroundColor: Colors.redAccent,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          String errorMessage = 'An error occurred: ${e.toString()}';
                                          if (e.toString().contains('ERROR_INVALID_CREDENTIAL') ||
                                              e.toString().contains('invalid-credential')) {
                                            errorMessage = 'Please enter your email or password.';
                                          } else if (e.toString().contains('Email or password not found')) {
                                            errorMessage = 'Email or password not found';
                                          }
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text(errorMessage, style: GoogleFonts.poppins()),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                        }
                                      }
                                    },
                              icon: loginViewModel.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.login), // Keep login icon for now, design doesn't show one explicitly
                              label: Text(
                                loginViewModel.isLoading ? 'Logging in...' : 'Login',
                                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20), // Spacing before RichText
                          
                          // Phone Login Option
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'Or',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // Phone Login Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: Colors.white, width: 1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PhoneLoginScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.phone,
                                color: Colors.white,
                              ),
                              label: Text(
                                'Login with phone number',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          RichText(
                            text: TextSpan(
                              text: 'Don\'t have an account? ',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Create Account',
                                  style: GoogleFonts.poppins(
                                    color: Colors.orange, // Orange for Create Account link
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const RegisterScreen(),
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
