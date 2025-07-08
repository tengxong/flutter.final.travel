import 'package:app_travel/screens/main_screen.dart';
import 'package:app_travel/services/auth_service.dart';
import 'package:app_travel/services/firebase_config.dart';
import 'package:app_travel/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:app_travel/model/login_view_model.dart';
import 'package:app_travel/screens/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_travel/screens/login_screen.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ปรับปรุง performance
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Initialize Firebase with proper error handling
  try {
    await FirebaseConfigService.setupFirebase();
  } catch (e) {
    debugPrint('Firebase setup failed: $e');
    // Continue with app startup even if Firebase fails
  }

  // บังคับ logout ทุกครั้งที่เปิดแอป
  try {
    await FirebaseAuth.instance.signOut();
    debugPrint('User signed out successfully');
  } catch (e) {
    debugPrint('Sign out failed: $e');
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

// This widget is the root of your application.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  DateTime? _lastActivityTime;
  static const _sessionTimeoutMinutes = 30; // 30 minutes for auto-logout

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLastActivityTime();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();

    if (state == AppLifecycleState.paused) {
      // App is going to the background
      _lastActivityTime = DateTime.now();
      await prefs.setString('lastActivityTime', _lastActivityTime!.toIso8601String());
    } else if (state == AppLifecycleState.resumed) {
      // App is coming to the foreground
      if (_lastActivityTime != null) {
        final currentTime = DateTime.now();
        final difference = currentTime.difference(_lastActivityTime!); // Correctly use _lastActivityTime
        if (difference.inMinutes >= _sessionTimeoutMinutes) {
          // If session expired, log out
          if (authService.currentUser != null) {
            await FirebaseAuth.instance.signOut();
            // Navigate to login screen after logout if necessary
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
              );
            }
          }
        }
      }
      // Reset last activity time on resume for active session
      _lastActivityTime = null; // Clear it to indicate active session
      await prefs.remove('lastActivityTime');
    }
  }

  Future<void> _loadLastActivityTime() async {
    final prefs = await SharedPreferences.getInstance();
    final String? lastActivityTimeString = prefs.getString('lastActivityTime');
    if (lastActivityTimeString != null) {
      _lastActivityTime = DateTime.parse(lastActivityTimeString);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Travel App',
      theme: AppTheme.lightTheme,
      routes: {
        '/home': (context) => const MainScreen(),
      },
      home: FutureBuilder<bool>(
        future: _checkIfFirstTime(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final bool hasSeenIntro = snapshot.data ?? false;

          if (!hasSeenIntro) {
            return const OnBoardingScreen();
          } else {
            // If intro has been seen, check authentication status
            return StreamBuilder<User?>(
              stream: authService.authStateChanges,
              builder: (context, authSnapshot) {
                if (authSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (authSnapshot.hasData) {
                  // User is logged in
                  return const MainScreen();
                } else {
                  // User is not logged in
                  return const LoginScreen();
                }
              },
            );
          }
        },
      ),
    );
  }

  Future<bool> _checkIfFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('hasSeenIntro') ?? false;
  }
}
