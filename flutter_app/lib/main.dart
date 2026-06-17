import 'package:flutter/material.dart';
import 'theme.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'pages/onboarding_page.dart';
import 'main_shell.dart';
import 'l10n/strings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.init();
  await NotificationService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDark = false;
  bool _notificationsEnabled = false;

  bool get isDark => _isDark;

  @override
  void initState() {
    super.initState();
    _loadNotificationPref();
  }

  Future<void> _loadNotificationPref() async {
    final enabled = await NotificationService().isEnabled;
    if (mounted) setState(() => _notificationsEnabled = enabled);
    if (enabled) NotificationService().scheduleDailyReminder();
  }

  void toggleDark() { setState(() => _isDark = !_isDark); }

  void toggleLanguage() {
    setState(() {
      AppStrings.setLanguage(!AppStrings.isTamil);
    });
  }

  void toggleNotifications() {
    final newVal = !_notificationsEnabled;
    NotificationService().setEnabled(newVal);
    setState(() => _notificationsEnabled = newVal);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tuition Attendance',
      debugShowCheckedModeBanner: false,
      theme: _isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: AuthService.isLoggedIn 
        ? MainShell(isDark: _isDark, onDarkToggle: toggleDark, onLanguageToggle: toggleLanguage, notificationsEnabled: _notificationsEnabled, onNotificationToggle: toggleNotifications) 
        : OnboardingPage(onDarkToggle: toggleDark, onLanguageToggle: toggleLanguage, notificationsEnabled: _notificationsEnabled, onNotificationToggle: toggleNotifications),
    );
  }
}
