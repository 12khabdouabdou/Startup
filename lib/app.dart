import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_router.dart';

/// Root application widget for FillExchange.
///
/// Integrated with app_router for navigation and auth guarding.
/// Uses Earth & Trust design system via AppTheme.
class FillExchangeApp extends ConsumerWidget {
  const FillExchangeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the router provider so updates trigger correct navigation behavior
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'FillExchange',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
