import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'core/services/offline_queue.dart';
import 'core/services/notification_service.dart';
import 'core/models/mock_data.dart';
import 'core/providers/auth_provider.dart';
import 'features/profile/providers/profile_provider.dart';

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
  // Mock Mode Toggle: Set to false to use real Firebase
  const bool useMockData = false;

  if (useMockData) {
    debugPrint('⚠️ Running in MOCK MODE - Bypassing Firebase Auth & Notifications');
    runApp(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) {
            final user = ref.watch(mockUserProvider);
            return Stream.value(MockData.getFirebaseUser(user));
          }),
          userDocProvider.overrideWith((ref) => Stream.value(ref.watch(mockUserProvider))),
        ],
        child: const FillExchangeApp(),
      ),
    );
  } else {
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const FillExchangeApp(),
      ),
    );

    // Initialize FCM Notifications asynchronously (Epic 5)
    // We do this AFTER runApp to avoid blocking the UI startup (AC-1 fix)
    container.read(notificationServiceProvider).initialize().catchError((e) {
      debugPrint('Error initializing notifications: $e');
    });
  }
}
