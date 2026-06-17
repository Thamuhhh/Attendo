import 'package:flutter/material.dart';
import 'theme.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/api_service.dart';
import 'pages/onboarding_page.dart';
import 'main_shell.dart';
import 'l10n/strings.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _initialized = false;
  bool _isDark = false;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.wait([
      AuthService.init(),
      NotificationService().initialize(),
    ]);
    if (!mounted) return;
    ApiService.startKeepAlive();
    if (AuthService.isLoggedIn) ApiService.warmUp();
    final enabled = await NotificationService().isEnabled;
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = enabled;
      _initialized = true;
    });
    NotificationService().scheduleDailyReminder();
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
      title: 'Attendo',
      debugShowCheckedModeBanner: false,
      theme: _isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: !_initialized
        ? const _Splash()
        : AuthService.isLoggedIn 
          ? MainShell(isDark: _isDark, onDarkToggle: toggleDark, onLanguageToggle: toggleLanguage, notificationsEnabled: _notificationsEnabled, onNotificationToggle: toggleNotifications) 
          : OnboardingPage(onDarkToggle: toggleDark, onLanguageToggle: toggleLanguage, notificationsEnabled: _notificationsEnabled, onNotificationToggle: toggleNotifications),
    );
  }
}

class _Splash extends StatefulWidget {
  const _Splash();
  @override
  State<_Splash> createState() => _SplashState();
}

class _SplashState extends State<_Splash> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primary, AppTheme.primaryLight],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.school_rounded, size: 48, color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text('Attendo', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                const SizedBox(height: 6),
                Text('Attendance Tracker', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7))),
                const SizedBox(height: 40),
                SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
