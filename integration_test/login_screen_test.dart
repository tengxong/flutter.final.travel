import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_travel/firebase_options.dart';
import 'package:app_travel/model/login_view_model.dart';
import 'package:app_travel/screens/login_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAuth.instance.signOut();
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
    expect(find.text('เข้าสู่ระบบ'), findsOneWidget);
  });
} 