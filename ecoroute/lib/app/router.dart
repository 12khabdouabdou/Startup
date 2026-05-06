import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../auth/bloc/auth_bloc.dart';
import '../auth/bloc/auth_state.dart';
import '../auth/views/splash_screen.dart';
import '../auth/views/login_screen.dart';
import '../auth/views/register_screen.dart';
import '../developer/views/developer_home.dart';
import '../hauler/views/hauler_home.dart';
import '../recycler/views/recycler_home.dart';
import '../admin/views/admin_dashboard.dart';
import '../waste/bloc/listing_bloc.dart';
import '../waste/views/listings_feed_screen.dart';
import '../waste/views/create_listing_screen.dart';
import '../booking/views/booking_detail_screen.dart';
import '../chat/views/chat_list_screen.dart';
import '../map/views/map_screen.dart';
import '../profile/views/profile_screen.dart';
import 'di.dart';
import '../waste/repository/listing_repository.dart';

class AppRouter {
  AppRouter._();

  static GoRouter router(AuthBloc authBloc) => GoRouter(
        initialLocation: '/splash',
        refreshListenable: _GoRouterRefreshStream(authBloc.stream),
        redirect: (context, state) {
          final authState = authBloc.state;
          final isLoggedIn = authState is AuthAuthenticated;
          final isLoggingIn = state.matchedLocation == '/login';
          final isRegistering = state.matchedLocation == '/register';
          final isSplash = state.matchedLocation == '/splash';

          if (isSplash) {
            return isLoggedIn
                ? '/${(authState as AuthAuthenticated).user.role}'
                : '/login';
          }

          if (isLoggedIn && (isLoggingIn || isRegistering)) {
            return '/${(authState as AuthAuthenticated).user.role}';
          }

          if (!isLoggedIn && !isLoggingIn && !isRegistering) {
            return '/login';
          }

          return null;
        },
        routes: [
          GoRoute(
            path: '/splash',
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
          ShellRoute(
            builder: (context, state, child) => BlocProvider<ListingBloc>(
              create: (_) =>
                  ListingBloc(getIt<ListingRepository>()),
              child: child,
            ),
            routes: [
              GoRoute(
                path: '/developer',
                builder: (context, state) => const DeveloperHome(),
                routes: [
                  GoRoute(
                    path: 'listings',
                    builder: (context, state) => const ListingsFeedScreen(),
                  ),
                  GoRoute(
                    path: 'listings/new',
                    builder: (context, state) => const CreateListingScreen(),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/hauler',
            builder: (context, state) => const HaulerHome(),
          ),
          GoRoute(
            path: '/recycler',
            builder: (context, state) => const RecyclerHome(),
          ),
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminDashboard(),
          ),
          GoRoute(
            path: '/bookings/:id',
            builder: (context, state) {
              final bookingId = state.pathParameters['id']!;
              return BookingDetailScreen(bookingId: bookingId);
            },
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) => const ChatListScreen(),
          ),
          GoRoute(
            path: '/map',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return MapScreen(
                isPickerMode: extra?['isPicker'] ?? false,
                initialPosition: extra?['initialPosition'] as LatLng?,
              );
            },
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) {
              final role = state.uri.queryParameters['role'] ?? 'developer';
              return ProfileScreen(role: role);
            },
          ),
        ],
      );
}

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
