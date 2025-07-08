import 'package:app_travel/utils/keyboard.dart';
import 'package:app_travel/model/profile.dart';
import 'package:app_travel/screens/login_screen.dart';
import 'package:app_travel/services/auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_travel/screens/main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formkey = GlobalKey<FormState>();
  Profile profile = Profile();
  final Future<FirebaseApp> firebase = Firebase.initializeApp();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureTextPassword = true;
  bool _obscureTextConfirmPassword = true;

  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      child: FutureBuilder(
        future: firebase,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: Center(child: Text('${snapshot.error}')),
            );
          }

          if (snapshot.connectionState == ConnectionState.done) {
            return Scaffold(
              body: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/background.jpeg',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    color: const Color.fromRGBO(0, 0, 0, 0.5),
                  ),
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 100),
                          Text(
                            'Create Account',
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 50),
                          Form(
                            key: formkey,
                            child: Column(
                              children: [
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Name',
                                    hintText: 'Enter your name',
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
                                    suffixIcon: Icon(Icons.person, color: Colors.grey[600]),
                                  ),
                                  validator: RequiredValidator(
                                    errorText: 'Please enter your username',
                                  ).call,
                                  onSaved: (String? username) {
                                    profile.username = username ?? '';
                                  },
                                  keyboardType: TextInputType.text,
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Phone Number',
                                    hintText: 'Enter your phone number',
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
                                    suffixIcon: Icon(Icons.phone, color: Colors.grey[600]),
                                  ),
                                  validator: MultiValidator([
                                    RequiredValidator(errorText: 'Please enter your phone number'),
                                    PatternValidator(r'^[0-9]{9,}$', errorText: 'Phone number must be at least 9 digits'),
                                  ]).call,
                                  keyboardType: TextInputType.phone,
                                  onSaved: (String? phone) {
                                    profile.phone = phone ?? '';
                                  },
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
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
                                    suffixIcon: Icon(Icons.email, color: Colors.grey[600]),
                                  ),
                                  validator: MultiValidator([
                                    RequiredValidator(errorText: 'Please enter your email'),
                                    EmailValidator(errorText: 'Invalid email format'),
                                  ]).call,
                                  keyboardType: TextInputType.emailAddress,
                                  onSaved: (String? email) {
                                    profile.email = email ?? '';
                                  },
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _passwordController,
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
                                        _obscureTextPassword ? Icons.visibility_off : Icons.visibility,
                                        color: Colors.grey[600],
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureTextPassword = !_obscureTextPassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: MultiValidator([
                                    RequiredValidator(errorText: 'Please enter your password'),
                                    MinLengthValidator(
                                      6,
                                      errorText: 'Password must be at least 6 characters',
                                    ),
                                  ]).call,
                                  obscureText: _obscureTextPassword,
                                  onSaved: (String? password) {
                                    profile.password = password ?? '';
                                  },
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureTextConfirmPassword,
                                  decoration: InputDecoration(
                                    labelText: 'Confirm password',
                                    hintText: 'Confirm your password',
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
                                        _obscureTextConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                        color: Colors.grey[600],
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureTextConfirmPassword = !_obscureTextConfirmPassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.isEmpty) {
                                      return 'Please confirm your password';
                                    }
                                    if (val != _passwordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
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
                                    onPressed: _isLoading
                                        ? null
                                        : () async {
                                            if (formkey.currentState!.validate()) {
                                              formkey.currentState!.save();

                                              setState(() {
                                                _isLoading = true;
                                              });

                                              final messenger = ScaffoldMessenger.of(context);
                                              final navigator = Navigator.of(context);

                                              try {
                                                await authService.value.singUp(
                                                  email: profile.email,
                                                  password: profile.password,
                                                  username: profile.username,
                                                  phone: profile.phone,
                                                );

                                                formkey.currentState?.reset();
                                                _confirmPasswordController.clear();
                                                if (!mounted) return;
                                                messenger.showSnackBar(
                                                  SnackBar(
                                                    content: Text('Registration successful', style: GoogleFonts.poppins()),
                                                    backgroundColor: Colors.green,
                                                  ),
                                                );
                                                navigator.pushAndRemoveUntil(
                                                  MaterialPageRoute(builder: (context) => const MainScreen()),
                                                  (route) => false,
                                                );
                                              } on FirebaseAuthException catch (e) {
                                                String message;
                                                switch (e.code) {
                                                  case 'email-already-in-use':
                                                    message = 'This email is already in use';
                                                    break;
                                                  case 'invalid-email':
                                                    message = 'Invalid email format';
                                                    break;
                                                  case 'operation-not-allowed':
                                                    message = 'Registration is disabled';
                                                    break;
                                                  case 'weak-password':
                                                    message = 'Password is too weak';
                                                    break;
                                                  default:
                                                    message = e.message ?? 'An error occurred during registration';
                                                }
                                                if (!mounted) return;
                                                messenger.showSnackBar(
                                                  SnackBar(
                                                    content: Text(message, style: GoogleFonts.poppins()),
                                                    backgroundColor: Colors.redAccent,
                                                  ),
                                                );
                                              } catch (e) {
                                                if (!mounted) return;
                                                messenger.showSnackBar(
                                                  SnackBar(
                                                    content: Text('An unexpected error occurred: $e', style: GoogleFonts.poppins()),
                                                    backgroundColor: Colors.redAccent,
                                                  ),
                                                );
                                              } finally {
                                                setState(() {
                                                  _isLoading = false;
                                                });
                                              }
                                            }
                                          },
                                    icon: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.person_add),
                                    label: Text(
                                      _isLoading ? 'Registering...' : 'Sign Up',
                                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                
                                // Phone Registration Option
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
                                RichText(
                                  text: TextSpan(
                                    text: 'Already have an account? ',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Login',
                                        style: GoogleFonts.poppins(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            Navigator.push(
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
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}