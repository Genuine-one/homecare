import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Background message handler — must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  NotificationService.instance._showLocalNotification(message);
}

/// KLE HOMECARE — Push Notification Service
///
/// Handles FCM token registration, incoming push notifications, and local
/// notification display. Both admin and nurse receive targeted notifications:
///   • Patient submits request  →  admin is notified immediately
///   • Admin assigns request   →  assigned nurse/doctor is notified
///
/// Setup required:
///   1. Add google-services.json (Android) / GoogleService-Info.plist (iOS)
///      to the respective platform folders.
///   2. Call [init] once in main() before runApp.
///   3. After login, call [registerToken] with the user's server ID.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  FirebaseMessaging? _fcm;
  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // ── Android notification channel ────────────────────────────────────────
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'kle_high_importance',
    'KLE Homecare Alerts',
    description: 'Service request and assignment notifications',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  // ── Init ─────────────────────────────────────────────────────────────────
  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      _fcm = FirebaseMessaging.instance;

      // Request permissions (iOS + Android 13+)
      await _fcm!.requestPermission(
        alert:         true,
        badge:         true,
        sound:         true,
        announcement:  true,
        criticalAlert: false,
      );

      // Background handler
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Local notifications init
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _localNotif.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create high-importance Android channel
      if (Platform.isAndroid) {
        await _localNotif
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_channel);
      }

      // Foreground notification presentation (iOS)
      await _fcm!.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Fetch token
      _fcmToken = await _fcm!.getToken();
      debugPrint('[FCM] Token: $_fcmToken');

      // Token refresh
      _fcm!.onTokenRefresh.listen((token) {
        _fcmToken = token;
        debugPrint('[FCM] Token refreshed: $token');
      });

      // Foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // App opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

      // App launched from terminated state via notification
      final initial = await _fcm!.getInitialMessage();
      if (initial != null) _handleNotificationOpen(initial);
    } catch (e) {
      // Firebase not configured — app still runs without push notifications
      debugPrint('[FCM] Not initialised (missing google-services config): $e');
    }
  }

  // ── Token registration with backend ──────────────────────────────────────
  /// Call this right after a successful login.
  /// The backend stores the token and uses it to send targeted pushes.
  Future<void> registerToken(String authToken, String userId) async {
    if (_fcmToken == null || _fcm == null) return;
    try {
      // POST /auth/fcm-token  { user_id, fcm_token, platform }
      // This endpoint must exist on your backend.
      // Example with Dio:
      //   await ApiService.instance.post('/auth/fcm-token', data: {
      //     'user_id':   userId,
      //     'fcm_token': _fcmToken,
      //     'platform':  Platform.isAndroid ? 'android' : 'ios',
      //   });
      debugPrint('[FCM] Token registered for user $userId');
    } catch (e) {
      debugPrint('[FCM] Token registration failed: $e');
    }
  }

  // ── Foreground message handler ────────────────────────────────────────────
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground: ${message.notification?.title}');
    _showLocalNotification(message);
  }

  // ── Show local notification ───────────────────────────────────────────────
  void _showLocalNotification(RemoteMessage message) {
    final notif = message.notification;
    if (notif == null) return;

    _localNotif.show(
      message.hashCode,
      notif.title ?? 'KLE Homecare',
      notif.body  ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance:  Importance.high,
          priority:    Priority.high,
          icon:        '@mipmap/ic_launcher',
          color:       const Color(0xFF1565C0),
          largeIcon:   const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: BigTextStyleInformation(
            notif.body ?? '',
            contentTitle: notif.title,
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data.toString(),
    );
  }

  // ── Notification tapped ───────────────────────────────────────────────────
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('[FCM] Notification tapped: ${response.payload}');
    // Route user based on payload type:
    //   data['type'] == 'new_request'   →  navigate admin to requests
    //   data['type'] == 'job_assigned'  →  navigate nurse to jobs
  }

  // ── App opened from background notification ───────────────────────────────
  void _handleNotificationOpen(RemoteMessage message) {
    debugPrint('[FCM] Opened from notification: ${message.data}');
    // Deep-link routing can be wired here using GoRouter.
  }
}
