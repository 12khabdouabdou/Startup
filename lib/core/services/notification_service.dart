import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Top-level handler for background/terminated messages.
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  _log.i('🔔 Background message: ${message.notification?.title}');
}

/// Manages FCM tokens, permissions, and message handling.
class NotificationService {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;

  NotificationService(this._messaging, this._firestore);

  // ─── Initialization ──────────────────────────────

  /// Call once at app startup (after Firebase.initializeApp)
  Future<void> initialize() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

    // Request permission (iOS + Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    _log.i('FCM permission: ${settings.authorizationStatus}');

    // Get and save token
    final token = await _messaging.getToken();
    if (token != null) {
      _log.i('FCM Token: ${token.substring(0, 20)}...');
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _log.i('FCM Token refreshed');
      // Token will be saved when user is authenticated via saveTokenForUser
    });

    // Foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap (app was in background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if app was opened from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  // ─── Token Management ────────────────────────────

  /// Save the FCM token to the user's Firestore document.
  /// Call this after the user signs in.
  Future<void> saveTokenForUser(String uid) async {
    final token = await _messaging.getToken();
    if (token == null) return;

    await _firestore.collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'lastTokenUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _log.i('FCM token saved for user $uid');
  }

  /// Remove the FCM token from the user's document (call on sign-out).
  Future<void> removeTokenForUser(String uid) async {
    final token = await _messaging.getToken();
    if (token == null) return;

    await _firestore.collection('users').doc(uid).update({
      'fcmTokens': FieldValue.arrayRemove([token]),
    });

    _log.i('FCM token removed for user $uid');
  }

  // ─── Topic Subscriptions (Geo-fenced) ────────────

  /// Subscribe to a geographic area topic for new listing alerts.
  /// Topics are region-based, e.g. "listings_region_downtown"
  Future<void> subscribeToRegion(String regionId) async {
    await _messaging.subscribeToTopic('listings_$regionId');
    _log.i('Subscribed to topic: listings_$regionId');
  }

  Future<void> unsubscribeFromRegion(String regionId) async {
    await _messaging.unsubscribeFromTopic('listings_$regionId');
    _log.i('Unsubscribed from topic: listings_$regionId');
  }

  /// Subscribe to job updates for a specific job
  Future<void> subscribeToJob(String jobId) async {
    await _messaging.subscribeToTopic('job_$jobId');
  }

  Future<void> unsubscribeFromJob(String jobId) async {
    await _messaging.unsubscribeFromTopic('job_$jobId');
  }

  // ─── Notification Settings ───────────────────────

  /// Get current notification preferences from Firestore
  Future<Map<String, bool>> getSettings(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) return _defaultSettings;

    final stored = data['notificationSettings'] as Map<String, dynamic>?;
    if (stored == null) return _defaultSettings;

    return {
      'newListings': stored['newListings'] as bool? ?? true,
      'jobUpdates': stored['jobUpdates'] as bool? ?? true,
      'messages': stored['messages'] as bool? ?? true,
    };
  }

  /// Update notification preferences
  Future<void> updateSettings(String uid, Map<String, bool> settings) async {
    await _firestore.collection('users').doc(uid).set({
      'notificationSettings': settings,
    }, SetOptions(merge: true));
  }

  static const _defaultSettings = {
    'newListings': true,
    'jobUpdates': true,
    'messages': true,
  };

  // ─── Message Handlers ────────────────────────────

  void _handleForegroundMessage(RemoteMessage message) {
    _log.i('🔔 Foreground message: ${message.notification?.title}');
    // In-app notification will be shown via a global key / overlay
    // This is handled by the NotificationOverlay widget
    _onForegroundMessage?.call(message);
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    _log.i('🔔 Opened from notification: ${message.data}');
    _onNotificationTap?.call(message);
  }

  // Callbacks for UI layer
  void Function(RemoteMessage)? _onForegroundMessage;
  void Function(RemoteMessage)? _onNotificationTap;

  void setForegroundHandler(void Function(RemoteMessage) handler) {
    _onForegroundMessage = handler;
  }

  void setNotificationTapHandler(void Function(RemoteMessage) handler) {
    _onNotificationTap = handler;
  }
}

// ─── Providers ───────────────────────────────────────

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    FirebaseMessaging.instance,
    FirebaseFirestore.instance,
  );
});
