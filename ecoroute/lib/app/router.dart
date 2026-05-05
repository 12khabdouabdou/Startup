import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../auth/bloc/auth_bloc.dart';
import '../auth/bloc/auth_state.dart';
import '../auth/views/splash_screen.dart';
import '../auth/views/login_screen.dart';
import '../auth/views/register_screen.dart';
import '../developer/views/developer_home.dart';
import '../hauler/views/hauler_home.dart';
import '../recycler/views/recycler_home.dart';
import '../admin/views/admin_dashboard.dart';
import '../waste/views/listings_feed_screen.dart';
import '../waste/views/create_listing_screen.dart';
import '../booking/views/booking_detail_screen.dart';
import '../chat/views/chat_list_screen.dart';
import '../map/views/map_screen.dart';
import '../profile/views/profile_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      // Auth routes
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
      
      // Developer routes
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
      
      // Hauler routes
      GoRoute(
        path: '/hauler',
        builder: (context, state) => const HaulerHome(),
      ),
      
      // Recycler routes
      GoRoute(
        path: '/recycler',
        builder: (context, state) => const RecyclerHome(),
      ),
      
      // Admin routes
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
      ),
      
      // Shared routes
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
        builder: (context, state) => const MapScreen(isPickerMode: false),
      ),
      
      GoRoute(
        path: '/profile',
        builder: (context, state) {
          final role = state.uri.queryParameters['role'] ?? 'developer';
          return ProfileScreen(role: role);
        },
      ),
    ],
    
    // Redirect logic based on authentication
    redirect: (context, state) {
      final isLoggedIn = context.read<AuthBloc>().state is AuthAuthenticated;
      final isLoggingIn = state.location == '/login';
      final isRegistering = state.location == '/register';
      final isSplash = state.location == '/splash';
      
      if (isSplash && !isLoggedIn) {
        return '/login';
      }
      
      if (isLoggedIn && (isLoggingIn || isRegistering || isSplash)) {
        // Redirect to appropriate home based on role
        final authState = context.read<AuthBloc>().state as AuthAuthenticated;
        final role = authState.user.role;
        return '/$role';
      }
      
      return null;
    },
  );
}
