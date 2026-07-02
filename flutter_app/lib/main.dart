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
import 'widgets/error_boundary.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppErrorBoundary.init();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.wait([
      NotificationService().initialize().catchError((_) {}),
      OfflineDb.database.then((_) {}).catchError((_) {}),
    ]);
    if (!mounted) return;

    SyncService.start();
    ApiService.startKeepAlive();

    final enabled = await NotificationService().isEnabled;
    if (!mounted) return;
    if (enabled != ref.read(settingsProvider).notificationsEnabled) {
      ref.read(settingsProvider.notifier).toggleNotifications();
    }

    if (AuthService.isLoggedIn) {
      ApiService.warmUp().timeout(const Duration(seconds: 30)).catchError((_) {});
    }
    NotificationService().scheduleAllReminders().catchError((_) {});
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
      home: auth.isLoggedIn
        ? const MainShell()
        : const OnboardingPage(),
    );
  }
}


