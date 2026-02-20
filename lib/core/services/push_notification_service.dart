import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/repositories/auth_repository.dart';

// Top-level background handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
}

class PushNotificationService {
  final SupabaseClient _supabase;
  final Logger _logger = Logger();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  PushNotificationService(this._supabase);

  Future<void> initialize() async {
    // 1. Initialize Local Notifications (for foreground alerts)
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    
    await _localNotifications.initialize(initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap logic here (e.g., deep linking)
      },
    );

    // 2. Request Permission (iOS/Web)
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      _logger.i('User granted permission');

      // 3. Get FCM Token & Save
      final token = await messaging.getToken();
      if (token != null) {
        _saveToken(token);
      }

      // 4. Listen for Token Refresh
      messaging.onTokenRefresh.listen(_saveToken);

      // 5. Handle Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _logger.d('Got a message whilst in the foreground!');
        _logger.d('Message: ${message.data}');

        if (message.notification != null) {
           _showLocalNotification(message);
        }
      });

      // 6. Set Background Handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 7. Listen for Auth Changes to save token on login
      _supabase.auth.onAuthStateChange.listen((data) {
        if (data.session != null) {
          messaging.getToken().then((token) {
             if (token != null) _saveToken(token);
          });
        }
      });

    } else {
      _logger.w('User declined or has not accepted permission');
    }
  }

  Future<void> _saveToken(String token) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Upsert token to users table
      await _supabase.from('users').upsert({
        'uid': user.id,
        'fcm_token': token,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'uid'); // Ensure uniqueness by UID
      _logger.i('FCM Token saved for user ${user.id}');
    } catch (e) {
      _logger.e('Failed to save FCM token: $e');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'Used for important notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  }
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(Supabase.instance.client);
});
