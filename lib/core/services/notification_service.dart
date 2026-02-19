// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

// Placeholder for Supabase Notification Service
class NotificationService {
  // final FirebaseMessaging _messaging;
  // final FirebaseFirestore _firestore;

  NotificationService();

  Future<void> initialize() async {
    _log.w('NotificationService: Firebase Messaging disabled for Supabase migration.');
    // TODO: Implement Supabase Realtime or Push Notifications
  }

  Future<void> saveTokenForUser(String uid) async {}
  Future<void> removeTokenForUser(String uid) async {}
  Future<void> subscribeToRegion(String regionId) async {}
  Future<void> unsubscribeFromRegion(String regionId) async {}
  Future<void> subscribeToJob(String jobId) async {}
  Future<void> unsubscribeFromJob(String jobId) async {}
  
  Future<Map<String, bool>> getSettings(String uid) async {
      return {'newListings': true, 'jobUpdates': true, 'messages': true};
  }

  Future<void> updateSettings(String uid, Map<String, bool> settings) async {}

  void setForegroundHandler(void Function(dynamic) handler) {}
  void setNotificationTapHandler(void Function(dynamic) handler) {}
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
