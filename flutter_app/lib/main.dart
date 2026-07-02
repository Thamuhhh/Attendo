import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'theme.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/api_service.dart';
import 'services/offline_db.dart';
import 'services/sync_service.dart';
import 'pages/onboarding_page.dart';
import 'main_shell.dart';
import 'providers/settings_provider.dart';
import 'providers/auth_provider.dart';
import 'l10n/strings.dart';
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
  bool _warmingUp = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final warmUpFuture = AuthService.isLoggedIn
        ? ApiService.warmUp().timeout(const Duration(seconds: 30)).catchError((_) {})
        : Future<void>.value();

    await Future.wait([
      NotificationService().initialize().catchError((_) {}),
      OfflineDb.database.then((_) {}).catchError((_) {}),
    ]);
    SyncService.start();
    if (!mounted) return;
    ApiService.startKeepAlive();
    final enabled = await NotificationService().isEnabled;
    if (!mounted) return;
    if (enabled != ref.read(settingsProvider).notificationsEnabled) {
      ref.read(settingsProvider.notifier).toggleNotifications();
    }

    await warmUpFuture;
    if (!mounted) return;
    _warmingUp = false;
    if (mounted) setState(() {});

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    setState(() => _initialized = true);
    NotificationService().scheduleDailyReminder();
    _checkUpdate();
  }

  Future<void> _checkUpdate() async {
    try {
      final data = await ApiService.getAppVersion();
      final remoteVer = data['version'] as String? ?? '1.0.0';
      final apkUrl = data['apkUrl'] as String? ?? '';
      final forceUpdate = data['forceUpdate'] as bool? ?? false;
      if (!AppVersion.isNewer(remoteVer) || apkUrl.isEmpty) return;
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: !forceUpdate,
        builder: (ctx) => PopScope(
          canPop: !forceUpdate,
          child: AlertDialog(
            title: Row(children: [
              const Icon(Icons.system_update_rounded, color: AppTheme.primary),
              const SizedBox(width: 10),
              Text(forceUpdate ? 'Update Required' : 'Update Available'),
            ]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Version $remoteVer is available. You have ${AppVersion.current}.'),
                if (forceUpdate) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(children: [
                      Icon(Icons.warning_amber_rounded, size: 18, color: AppTheme.danger),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This update is mandatory. Please update to continue using the app.',
                          style: TextStyle(fontSize: 13, color: AppTheme.danger),
                        ),
                      ),
                    ]),
                  ),
                ],
              ],
            ),
            actions: [
              if (!forceUpdate)
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
        ? _Splash(connecting: _warmingUp)
        : auth.isLoggedIn
          ? const MainShell()
          : const OnboardingPage(),
    );
  }
}

class _Splash extends StatefulWidget {
  final bool connecting;
  const _Splash({this.connecting = false});
  @override
  State<_Splash> createState() => _SplashState();
}

class _SplashState extends State<_Splash> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
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
            begin: Alignment(-0.2, -0.5),
            end: Alignment(0.8, 1.2),
            colors: [AppTheme.primary, AppTheme.primaryDark],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -100, right: -100,
              child: Container(
                width: 300, height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.03),
                ),
              ),
            ),
            Positioned(
              bottom: -80, left: -80,
              child: Container(
                width: 250, height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.03),
                ),
              ),
            ),
            Center(
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 96, height: 96,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.school_rounded, size: 52, color: Colors.white),
                      ),
                      const SizedBox(height: 24),
                      const Text('Attendo', style: TextStyle(
                        fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white,
                        letterSpacing: 1.5, wordSpacing: 2,
                      )),
                      const SizedBox(height: 8),
                      Text('Attendance Tracker', style: TextStyle(
                        fontSize: 15, color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 2, fontWeight: FontWeight.w300,
                      )),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: 28, height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedOpacity(
                        opacity: widget.connecting ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 400),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6, height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green.withValues(alpha: 0.7),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppStrings.get('connecting'),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.7),
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
