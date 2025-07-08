// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:flutter/material.dart';
import 'dart:io';

ValueNotifier<AuthService> authService = ValueNotifier(AuthService());

class AuthService with ChangeNotifier {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Instance of Firestore

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  Future<bool> _checkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<User?> singIn({
    required String email,
    required String password,
  }) async {
    try {
      // ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต
      if (!await _checkConnection()) {
        throw Exception(  'Cannot connect to the internet. Please check your connection');
      }

      final user = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (firebaseAuth.currentUser != null) {
        try {
          final userDoc = await _firestore
              .collection('users')
              .doc(firebaseAuth.currentUser!.uid)
              .get();
              
          if (userDoc.exists) {
            notifyListeners();
          }
        } catch (e) {
          debugPrint('Error fetching user data: $e');
          // ไม่ throw error เนื่องจาก login สำเร็จแล้ว
        }
      }
      
      return user.user;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Email not found';
          break;
        case 'wrong-password':
          errorMessage = 'Password is incorrect';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many login attempts. Please try again later';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred during login';
      }
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('Unexpected error during sign in: $e');
          throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<void> singUp({
    required String email,
    required String password,
    required String phone,
    required String username,
  }) async {
    try {
      if (!await _checkConnection()) {
        throw Exception('Cannot connect to the internet. Please check your connection');
      }

      await firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (firebaseAuth.currentUser != null) {
        try {
          Map<String, dynamic> userData = {
            'username': username,
            'email': email,
            'phone': phone,
            'createdAt': Timestamp.now(),
          };
          await _firestore.collection('users').doc(firebaseAuth.currentUser!.uid).set(userData);
        } catch (e) {
          debugPrint('Error saving user data: $e');
          await firebaseAuth.currentUser?.delete();
          throw Exception('Cannot create account. Please try again');
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email is already in use';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format';
          break;
        case 'operation-not-allowed':
              errorMessage = 'Registration is disabled';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred during registration';
      }
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('Unexpected error during sign up: $e');
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // signOut function moved to unused_files/lib/services/auth_service_logout.dart

  Future<void> resetPassword({required String email}) async {
    await firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateUsername({required String username}) async {
    if (currentUser != null) {
      await currentUser!.updateDisplayName(username);
      // Optional: Update username in Firestore as well
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'username': username,
      });
      notifyListeners();
    }
  }

  // deleteAccount function moved to unused_files/lib/services/auth_service_logout.dart

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    if (currentUser != null) {
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await currentUser!.reauthenticateWithCredential(credential);
      await currentUser!.updatePassword(newPassword);
      notifyListeners();
    }
  }

  Future<UserCredential> signInWithPhone({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await firebaseAuth.signInWithCredential(credential);
  }

  // เพิ่มเมธอดสำหรับส่ง OTP ไปยังเบอร์โทรศัพท์
  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onError,
  }) async {
    try {
      if (!await _checkConnection()) {
        onError('Cannot connect to the internet. Please check your connection');
        return;
      }

      await firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification if Android supports it
          try {
            await firebaseAuth.signInWithCredential(credential);
          } catch (e) {
            debugPrint('Auto-verification failed: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          String errorMessage;
          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage = 'Invalid phone number';
              break;
            case 'too-many-requests':
              errorMessage = 'Too many requests. Please try again later';
              break;
            case 'quota-exceeded':
              errorMessage = 'SMS quota exceeded. Please try again later';
              break;
            case 'billing-not-enabled':
              errorMessage = 'SMS service is not enabled. Please contact support';
              break;
            case 'app-not-authorized':
              errorMessage = 'App not authorized to send SMS';
              break;
            default:
              errorMessage = e.message ?? 'An error occurred during OTP sending';
          }
          debugPrint('SMS verification failed: ${e.code} - ${e.message}');
          onError(errorMessage);
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('SMS code sent successfully');
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('SMS auto-retrieval timeout');
          // Handle timeout if needed
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      debugPrint('Unexpected error in sendOTP: $e');
      onError('An unexpected error occurred: $e');
    }
  }

  // เมธอดสำหรับยืนยัน OTP และเข้าสู่ระบบ
  Future<User?> verifyOTPAndSignIn({
    required String verificationId,
    required String smsCode,
    String? username, // เพิ่ม parameter สำหรับการลงทะเบียน
  }) async {
    try {
      if (!await _checkConnection()) {
        throw Exception('Cannot connect to the internet. Please check your connection');
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await firebaseAuth.signInWithCredential(credential);
      
      // ตรวจสอบว่าผู้ใช้มีข้อมูลใน Firestore หรือไม่
      if (userCredential.user != null) {
        try {
          final userDoc = await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();
              
          if (!userDoc.exists) {
            // ถ้าไม่มีข้อมูลใน Firestore ให้สร้างข้อมูลใหม่ (สำหรับการลงทะเบียน)
            Map<String, dynamic> userData = {
              'phone': userCredential.user!.phoneNumber,
              'createdAt': Timestamp.now(),
              'lastLogin': Timestamp.now(),
            };
            
            // เพิ่ม username ถ้ามี (สำหรับการลงทะเบียน)
            if (username != null && username.isNotEmpty) {
              userData['username'] = username;
            }
            
            await _firestore.collection('users').doc(userCredential.user!.uid).set(userData);
          } else {
            // อัปเดตเวลาล็อกอินล่าสุด
            await _firestore.collection('users').doc(userCredential.user!.uid).update({
              'lastLogin': Timestamp.now(),
            });
          }
        } catch (e) {
          debugPrint('Error handling user data: $e');
          // ไม่ throw error เนื่องจาก login สำเร็จแล้ว
        }
      }
      
      notifyListeners();
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = 'Invalid OTP';
          break;
        case 'invalid-verification-id':
          errorMessage = 'Invalid verification code';
          break;
        case 'session-expired':
          errorMessage = 'Session expired. Please request a new OTP';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred during OTP verification';
      }
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('Unexpected error during OTP verification: $e');
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // เมธอดสำหรับลงทะเบียนด้วยเบอร์โทรศัพท์
  Future<void> signUpWithPhone({
    required String phoneNumber,
    required String username,
  }) async {
    try {
      if (!await _checkConnection()) {
          throw Exception('Cannot connect to the internet. Please check your connection');
      }

      // สำหรับการลงทะเบียนด้วยเบอร์โทรศัพท์ เราจะใช้ OTP verification
      // ข้อมูลผู้ใช้จะถูกสร้างหลังจากยืนยัน OTP สำเร็จ
      // เมธอดนี้จะถูกเรียกหลังจาก verifyOTPAndSignIn สำเร็จ
      
      if (firebaseAuth.currentUser != null) {
        try {
          Map<String, dynamic> userData = {
            'username': username,
            'phone': phoneNumber,
            'createdAt': Timestamp.now(),
            'lastLogin': Timestamp.now(),
          };
          
          await _firestore.collection('users').doc(firebaseAuth.currentUser!.uid).set(userData);
        } catch (e) {
          debugPrint('Error saving user data: $e');
          throw Exception('Cannot create account. Please try again');
        }
      }
    } catch (e) {
      debugPrint('Unexpected error during phone sign up: $e');
        throw Exception('An unexpected error occurred: $e');
    }
  }
}
