import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_travel/services/auth_service.dart'; // ตรวจสอบเส้นทางให้ถูกต้อง

class LoginViewModel extends ChangeNotifier {
  // --- 1. State Variables ---
  String _email = '';
  String _password = '';
  bool _isRemember = false;
  bool _isLoading = false;
  String? _errorMessage; // สำหรับเก็บข้อความผิดพลาด

  // --- 2. Getters (สำหรับให้ UI อ่านค่า) ---
  String get email => _email;
  String get password => _password;
  bool get isRemember => _isRemember;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Instance ของ AuthService (จะถูก inject ผ่าน Provider ในอนาคต หรือถ้าเป็น singleton ก็ใช้ authService.value)
  // ในตัวอย่างนี้จะใช้ authService.value ตามที่โค้ดเดิมของคุณตั้งไว้
  final AuthService _authService = AuthService(); // หรือใช้ Provider.of<AuthService>(context, listen: false) ในเมธอด signInUser

  // --- 3. Constructor ---
  // เรียก loadSavedCredentials() เมื่อ ViewModel ถูกสร้างขึ้น
  LoginViewModel() {
    loadSavedCredentials();
  }

  // --- 4. Setters / Methods (สำหรับเปลี่ยนสถานะและจัดการตรรกะ) ---

  // อัปเดตอีเมลและแจ้งเตือนผู้ฟัง
  void setEmail(String value) {
    _email = value;
    // ไม่ต้อง notifyListeners() ทุกครั้งที่พิมพ์เพื่อประสิทธิภาพ
    // จะ notify เมื่อข้อมูลถูกใช้ (เช่น เมื่อกดปุ่ม login) หรือถ้ามีการ validate แบบ real-time
  }

  // อัปเดตรหัสผ่านและแจ้งเตือนผู้ฟัง
  void setPassword(String value) {
    _password = value;
    // ไม่ต้อง notifyListeners() ทุกครั้งที่พิมพ์
  }

  // สลับสถานะ Remember Me และแจ้งเตือนผู้ฟัง
  void toggleRememberMe(bool? value) {
    _isRemember = value ?? false;
    notifyListeners(); // แจ้งเตือนเพื่อให้ CheckboxListTile อัปเดต UI
  }

  // ตั้งค่าสถานะการโหลดและแจ้งเตือนผู้ฟัง
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners(); // แจ้งเตือนเพื่อให้ปุ่ม Login อัปเดต UI (แสดง/ซ่อน CircularProgressIndicator)
  }

  // ตั้งค่าข้อความผิดพลาดและแจ้งเตือนผู้ฟัง
  void setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners(); // แจ้งเตือนเพื่อให้ SnackBar แสดงข้อผิดพลาด
  }

  // โหลดข้อมูลเข้าสู่ระบบที่บันทึกไว้
  Future<void> loadSavedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isRemember = prefs.getBool('remember_me') ?? false;
    if (_isRemember) {
      _email = prefs.getString('email') ?? '';
      _password = prefs.getString('password') ?? '';
    }
    // หลังจากโหลดเสร็จ ให้แจ้งเตือนเพื่อให้ TextFormField ที่ผูกกับ ViewModel อัปเดต initialValue
    notifyListeners();
  }

  // บันทึกข้อมูลเข้าสู่ระบบ
  Future<void> saveCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_isRemember) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('email', _email);
      await prefs.setString('password', _password);
    } else {
      await prefs.clear(); // ล้างข้อมูลหากไม่ต้องการจำ
    }
  }

  // เมธอดหลักสำหรับเข้าสู่ระบบ
  Future<bool> signInUser() async {
    setLoading(true); // เริ่มการโหลด
    setErrorMessage(null); // ล้างข้อผิดพลาดเก่า

    try {
      // เรียกใช้เมธอด singIn จาก AuthService
      // ถ้า AuthService ถูก provide ด้วย Provider, คุณจะต้องเข้าถึงมันผ่าน context.read<AuthService>()
      // แต่ในตัวอย่างนี้ ผมจะใช้ authService.value ตามที่คุณประกาศไว้ใน auth_service.dart
      await _authService.singIn( // หรือใช้ Provider.of<AuthService>(context, listen: false).singIn
        email: _email,
        password: _password,
      );

      // ถ้าเข้าสู่ระบบสำเร็จ ให้บันทึกข้อมูล (ถ้าเลือกจำ)
      await saveCredentials();
      return true; // สำเร็จ
    } on FirebaseAuthException catch (e) {
      // จัดการข้อผิดพลาดเฉพาะจาก Firebase Authentication
      String message;
      if (e.code == 'user-not-found') {
        message = 'อีเมลนี้ยังไม่มีในระบบ';
      } else if (e.code == 'wrong-password') {
        message = 'รหัสผ่านไม่ถูกต้อง';
      } else if (e.code == 'invalid-email') {
        message = 'รูปแบบอีเมลไม่ถูกต้อง';
      } else if (e.code == 'user-disabled') {
        message = 'บัญชีนี้ถูกระงับการใช้งาน';
      } else if (e.code == 'too-many-requests') {
        message = 'มีการพยายามเข้าสู่ระบบมากเกินไป กรุณาลองใหม่ในภายหลัง';
      } else {
        // ข้อผิดพลาดอื่นๆ ที่ไม่รู้จัก
        message = e.message ?? 'เกิดข้อผิดพลาดที่ไม่รู้จัก';
      }
      setErrorMessage(message); // ตั้งค่าข้อความผิดพลาด
      return false; // ไม่สำเร็จ
    } finally {
      setLoading(false); // หยุดการโหลดไม่ว่าจะสำเร็จหรือไม่
    }
  }
}