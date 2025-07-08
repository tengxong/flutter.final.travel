import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

class FirebaseConfigService {
  static bool _isInitialized = false;
  static bool _isAppCheckActivated = false;

  static bool get isInitialized => _isInitialized;
  static bool get isAppCheckActivated => _isAppCheckActivated;

  /// Initialize Firebase with proper error handling
  static Future<void> initializeFirebase() async {
    if (_isInitialized) {
      debugPrint('Firebase already initialized');
      return;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isInitialized = true;
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
      rethrow;
    }
  }

  /// Activate Firebase App Check with fallback options
  static Future<void> activateAppCheck() async {
    if (!_isInitialized) {
      debugPrint('Firebase not initialized. Initializing first...');
      await initializeFirebase();
    }

    if (_isAppCheckActivated) {
      debugPrint('App Check already activated');
      return;
    }

    try {
      // Try production providers first
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        // appleProvider: AppleProvider.deviceCheck, // Uncomment for iOS
      );
      _isAppCheckActivated = true;
      debugPrint('Firebase App Check activated with production provider');
    } catch (e) {
      debugPrint('Production App Check activation failed: $e');
      // Fallback to debug provider for development
      try {
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.debug,
          // appleProvider: AppleProvider.debug, // Uncomment for iOS
        );
        _isAppCheckActivated = true;
        debugPrint('Firebase App Check activated with debug provider');
      } catch (fallbackError) {
        debugPrint('Debug App Check activation also failed: $fallbackError');
        // Don't rethrow - App Check is optional for basic functionality
      }
    }
  }

  /// Complete Firebase setup
  static Future<void> setupFirebase() async {
    try {
      await initializeFirebase();
      await activateAppCheck();
      debugPrint('Firebase setup completed successfully');
    } catch (e) {
      debugPrint('Firebase setup failed: $e');
      rethrow;
    }
  }

  /// Get App Check token with error handling
  static Future<String?> getAppCheckToken() async {
    if (!_isAppCheckActivated) {
      debugPrint('App Check not activated');
      return null;
    }

    try {
      final token = await FirebaseAppCheck.instance.getToken();
      debugPrint('App Check token retrieved successfully');
      return token;
    } catch (e) {
      debugPrint('Failed to get App Check token: $e');
      return null;
    }
  }
} 