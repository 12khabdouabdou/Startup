import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'core/services/offline_queue.dart';
import 'core/services/notification_service.dart';

/// Entry point for the FillExchange application.
///
/// Initializes Firebase, Hive, FCM, and other core services.
/// Wraps the app in Riverpod's [ProviderScope].
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive (Offline capability - AC-2)
  await Hive.initFlutter();
  Hive.registerAdapter(QueuedActionAdapter());
  // Open the offline queue box immediately so it's ready for OfflineQueue service
  await Hive.openBox<QueuedAction>(OfflineQueue.boxName);

  // Initialize Firebase (AC-1)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable Firestore Offline Persistence (AC-1)
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Initialize FCM Notifications (Epic 5)
  final container = ProviderContainer();
  final notificationService = container.read(notificationServiceProvider);
  await notificationService.initialize();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const FillExchangeApp(),
    ),
  );
}
