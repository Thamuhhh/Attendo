import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/push_notification_service.dart';
import 'services/api_service.dart';
import 'services/offline_db.dart';
import 'services/sync_service.dart';
import 'pages/onboarding_page.dart';
import 'main_shell.dart';
import 'providers/settings_provider.dart';
import 'providers/auth_provider.dart';
import 'l10n/strings.dart';
import 'widgets/error_boundary.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      PushNotificationService().initialize().catchError((_) {}),
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
      PushNotificationService().sendTokenToServer().catchError((_) {});
      ApiService.warmUp().timeout(const Duration(seconds: 30)).catchError((_) {});
    }
    NotificationService().scheduleAllReminders().catchError((_) {});
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


