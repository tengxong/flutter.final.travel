import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:app_travel/screens/login_screen.dart';
import 'package:app_travel/model/login_view_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_travel/firebase_options.dart';

// Mock LoginViewModel ที่ไม่เรียก Firebase จริง
class MockLoginViewModel extends LoginViewModel {
  void loginWithEmail(String email, String password) {
    // ไม่ต้องทำอะไร
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  });

  testWidgets('LoginScreen has a login button', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<LoginViewModel>(
        create: (_) => LoginViewModel(),
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );
    // ตรวจสอบว่ามีปุ่มที่มีข้อความว่า 'เข้าสู่ระบบ' อยู่ในหน้า
    expect(find.text('เข้าสู่ระบบ'), findsOneWidget);
  });
} 