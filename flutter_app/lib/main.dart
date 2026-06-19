import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'theme.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/api_service.dart';
import 'pages/onboarding_page.dart';
import 'main_shell.dart';
import 'providers/settings_provider.dart';
import 'providers/auth_provider.dart';
import 'utils/app_version.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await NotificationService().initialize();
    if (!mounted) return;
    ApiService.startKeepAlive();
    if (AuthService.isLoggedIn) ApiService.warmUp();
    final enabled = await NotificationService().isEnabled;
    if (!mounted) return;
    if (enabled != ref.read(settingsProvider).notificationsEnabled) {
      ref.read(settingsProvider.notifier).toggleNotifications();
    }
    setState(() => _initialized = true);
    NotificationService().scheduleDailyReminder();

    _checkUpdate();
  }

  Future<void> _checkUpdate() async {
    try {
      final data = await ApiService.getAppVersion();
      final remoteVer = data['version'] as String? ?? '1.0.0';
      final apkUrl = data['apkUrl'] as String? ?? '';
      if (!AppVersion.isNewer(remoteVer) || apkUrl.isEmpty) return;
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Row(children: [
            const Icon(Icons.system_update_rounded, color: AppTheme.primary),
            const SizedBox(width: 10),
            const Text('Update Available'),
          ]),
          content: Text('Version $remoteVer is available. You have ${AppVersion.current}.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Later'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Update'),
              onPressed: () async {
                Navigator.pop(ctx);
                await _downloadAndInstall(apkUrl);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    } catch (_) {}
  }

  Future<void> _downloadAndInstall(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final auth = ref.watch(authProvider);

    return MaterialApp(
      title: 'Attendo',
      debugShowCheckedModeBanner: false,
      theme: settings.isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: !_initialized
        ? const _Splash()
        : auth.isLoggedIn
          ? const MainShell()
          : const OnboardingPage(),
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
