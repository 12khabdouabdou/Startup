import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waste_logistics/screens/splash/splash_screen.dart';
import 'package:waste_logistics/screens/auth/login_screen.dart';
import 'package:waste_logistics/screens/auth/register_screen.dart';
import 'package:waste_logistics/screens/customer/home_screen.dart';
import 'package:waste_logistics/screens/customer/schedule_pickup_screen.dart';
import 'package:waste_logistics/screens/customer/tracking_screen.dart';
import 'package:waste_logistics/screens/recycler/home_screen.dart' as recycler;
import 'package:waste_logistics/screens/driver/home_screen.dart' as driver;
import 'package:waste_logistics/screens/admin/dashboard_screen.dart';
import 'package:waste_logistics/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  runApp(const ProviderScope(child: MyApp()));
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/customer/home',
        builder: (context, state) => const CustomerHomeScreen(),
      ),
      GoRoute(
        path: '/customer/schedule',
        builder: (context, state) => const SchedulePickupScreen(),
      ),
      GoRoute(
        path: '/customer/tracking/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return TrackingScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/recycler/home',
        builder: (context, state) => const recycler.RecyclerHomeScreen(),
      ),
      GoRoute(
        path: '/driver/home',
        builder: (context, state) => const driver.DriverHomeScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
  );
});

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Waste Logistics',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
