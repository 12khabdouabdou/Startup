import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'core/services/offline_queue.dart';
import 'features/notifications/services/push_notification_service.dart';
import 'core/models/mock_data.dart';
import 'core/providers/auth_provider.dart';
import 'features/profile/providers/profile_provider.dart';

/// Entry point for the FillExchange application.
///
/// Initializes Supabase, Hive, and other core services.
/// Wraps the app in Riverpod's [ProviderScope].
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive (Offline capability - AC-2)
  await Hive.initFlutter();
  Hive.registerAdapter(QueuedActionAdapter());
  // Open the offline queue box immediately so it's ready for OfflineQueue service
  await Hive.openBox<QueuedAction>(OfflineQueue.boxName);

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://tjzquqbsfjqwcasdwtem.supabase.co',
    anonKey: 'sb_publishable_bJSHQgy7SkhpzdOHorYEcA_uCQpUU1d',
  );

  // Initialize Firebase (Push Notifications - AC-3)
  // Note: Firebase.initializeApp() requires configuration files (google-services.json)
  // We wrap this to allow the app to run even if not fully configured yet
  try {
    // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  final container = ProviderContainer();
  // Mock Mode Toggle: Set to false to use real Supabase
  const bool useMockData = false;

  if (useMockData) {
    debugPrint('⚠️ Running in MOCK MODE - Bypassing Supabase Auth');
    runApp(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) {
            final user = ref.watch(mockUserProvider);
            return Stream.value(MockData.getSupabaseUser(user));
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
    
    // Initialize notification service
    try {
      container.read(pushNotificationServiceProvider).initialize();
    } catch (e) {
      debugPrint('Push Notification service failed to start: $e');
    }
  }
}
