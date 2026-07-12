import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._();
  factory PushNotificationService() => _instance;
  PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  bool _initialized = false;

  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp();

      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        return;
      }

      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        await _registerToken(_fcmToken!);
      }

      _messaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        _registerToken(token);
      });

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      await _setupLocalNotifications();

      _initialized = true;
    } catch (e) {
      print('Push notification init failed: $e');
    }
  }

  Future<void> _setupLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
        android: androidSettings, iOS: iosSettings);
    await _localNotifications.initialize(settings: initSettings);

    const channel = AndroidNotificationChannel(
      'push_notifications',
      'Push Notifications',
      description: 'Notifications from Attendo server',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final details = const NotificationDetails(
      android: AndroidNotificationDetails(
        'push_notifications',
        'Push Notifications',
        channelDescription: 'Notifications from Attendo server',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
      payload: jsonEncode(message.data),
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];
    if (type == 'attendance') {
    } else if (type == 'fee') {}
  }

  Future<void> _registerToken(String token) async {
    if (!AuthService.isLoggedIn) return;
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/fcm-token'),
        headers: AuthService.authHeaders,
        body: jsonEncode({'fcmToken': token}),
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
      }
    } catch (e) {
      print('FCM token registration failed: $e');
    }
  }

  Future<void> sendTokenToServer() async {
    if (_fcmToken != null) {
      await _registerToken(_fcmToken!);
    }
  }

  Future<void> removeTokenFromServer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token');
    } catch (_) {}
  }
}
