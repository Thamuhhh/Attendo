import 'package:flutter/material.dart';
import 'theme.dart';
import 'services/auth_service.dart';
import 'pages/onboarding_page.dart';
import 'main_shell.dart';
import 'l10n/strings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDark = false;

  bool get isDark => _isDark;

  void toggleDark() { setState(() => _isDark = !_isDark); }

  void toggleLanguage() {
    setState(() {
      AppStrings.setLanguage(!AppStrings.isTamil);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tuition Attendance',
      debugShowCheckedModeBanner: false,
      theme: _isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: AuthService.isLoggedIn ? MainShell(isDark: _isDark, onDarkToggle: toggleDark, onLanguageToggle: toggleLanguage) : OnboardingPage(onDarkToggle: toggleDark, onLanguageToggle: toggleLanguage),
    );
  }
}
