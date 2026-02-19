import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../profile/repositories/profile_repository.dart';
import '../../auth/repositories/auth_repository.dart';

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final Ref _ref;

  PushNotificationService(this._ref);

  Future<void> initialize() async {
    // Request permissions (especially for iOS)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permission');
    }

    // Get the token
    String? token = await _fcm.getToken();
    if (token != null) {
      _updateTokenInBackend(token);
    }

    // Listen to token refresh
    _fcm.onTokenRefresh.listen(_updateTokenInBackend);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });

    // Handle notification clicks when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification clicked!');
      // TODO: Handle navigation based on message.data
    });
  }

  Future<void> _updateTokenInBackend(String token) async {
    final user = _ref.read(authRepositoryProvider).currentUser;
    if (user != null) {
      await _ref.read(profileRepositoryProvider).updateUser(user.id, {'fcm_token': token});
    }
  }
}

// Global background handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref);
});
