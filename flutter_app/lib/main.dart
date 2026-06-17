import 'package:flutter/material.dart';
import 'theme.dart';
import 'services/auth_service.dart';
import 'pages/onboarding_page.dart';
import 'main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tuition Attendance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: AuthService.isLoggedIn ? const MainShell() : const OnboardingPage(),
    );
  }
}
