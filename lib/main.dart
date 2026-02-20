import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/push_notification_service.dart';

import 'app.dart';
import 'core/services/offline_queue.dart';
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
    
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      // Initialize Push Notifications if Firebase is ready
      container.read(pushNotificationServiceProvider).initialize();
    } catch (e) {
      debugPrint('Warning: Firebase or Push Notifications failure: $e');
    }
  }
}
