import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:supabase_flutter/supabase_flutter.dart';


import '../providers/auth_provider.dart';
import 'shell_scaffold.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/listings/screens/home_screen.dart';
import '../../features/map/screens/map_screen.dart';
import '../../features/jobs/screens/activity_screen.dart';
import '../../features/jobs/screens/hauler_job_board_screen.dart';
import '../../features/jobs/screens/job_detail_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/listings/screens/listing_detail_screen.dart';
import '../../features/jobs/models/job_model.dart';

import '../../features/auth/screens/role_selection_screen.dart';
import '../../features/auth/screens/registration_screen.dart';
import '../../features/verification/screens/verify_docs_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart'; // Admin Dashboard
import '../../features/admin/screens/user_approval_screen.dart'; // User Approval
import '../../features/listings/screens/create_listing_screen.dart'; // Create Listing
import '../../features/listings/screens/my_listings_screen.dart'; // My Listings
import '../../features/notifications/screens/notification_settings_screen.dart';
import '../../features/notifications/screens/notification_center_screen.dart';
import '../../features/compliance/screens/manifest_screen.dart';
import '../../features/compliance/screens/review_screen.dart';
import '../../features/compliance/screens/billing_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/messaging/screens/chat_list_screen.dart';
import '../../features/messaging/screens/chat_screen.dart';
import '../../features/profile/providers/profile_provider.dart';
import '../models/app_user.dart';

/// Notifier to refresh router when auth or profile state changes
class AuthNotifier extends ChangeNotifier {
  final Ref ref;

  AuthNotifier(this.ref) {
    ref.listen<AsyncValue<User?>>(authStateProvider, (_, __) => notifyListeners());
    ref.listen<AsyncValue<AppUser?>>(userDocProvider, (_, __) => notifyListeners());
  }
}

/// Provides the GoRouter configuration with auth guarding and profile-based redirection.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = AuthNotifier(ref);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final userDocState = ref.read(userDocProvider);

      final isLoggedIn = authState.valueOrNull != null;
      final isLoggingIn = state.uri.path == '/login';

      if (authState.isLoading || userDocState.isLoading) {
        return null; // Stay on splash or loading screen if determining auth/profile
      }

      if (!isLoggedIn) {
        return isLoggingIn ? null : '/login';
      }

      // Logged in. Check profile status.
      final userDoc = userDocState.valueOrNull;

      if (userDoc == null) {
        // New user (no profile doc) -> Role Selection
        if (state.uri.path == '/auth/role-selection' || state.uri.path == '/auth/register') {
           return null;
        }
        return '/auth/role-selection';
      }

      // Existing user. Check status.
      if (userDoc.status == UserStatus.pending) {
        if (state.uri.path != '/auth/verify-docs') return '/auth/verify-docs';
        return null;
      }
      
      // Approved
      if (userDoc.status == UserStatus.approved) {
         if (userDoc.role == UserRole.admin) {
            if (!state.uri.path.startsWith('/admin')) return '/admin/dashboard';
         } else {
            // Normal user attempting to access admin
            if (state.uri.path.startsWith('/admin')) return '/home';
         }
         
         if (isLoggingIn || state.uri.path.startsWith('/auth')) {
            return userDoc.role == UserRole.admin ? '/admin/dashboard' : '/home';
         }
      }

      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ShellScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
              routes: [
                GoRoute(path: 'listings/:id', builder: (context, state) => ListingDetailScreen(listingId: state.pathParameters['id'] ?? '')),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/map', builder: (context, state) => const MapScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/activity', builder: (context, state) => const ActivityScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
          ]),
        ],
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) {
           final role = state.extra as UserRole?;
           return RegistrationScreen(role: role);
        },
      ),
      GoRoute(
        path: '/auth/verify-docs',
        builder: (context, state) => const VerifyDocsScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/user/:uid',
        builder: (context, state) {
           final user = state.extra as AppUser?;
           if (user == null) return const Scaffold(body: Center(child: Text('User details not provided')));
           return UserApprovalScreen(user: user);
        },
      ),
      GoRoute(
        path: '/listings/create',
        builder: (context, state) => const CreateListingScreen(),
      ),
      GoRoute(
        path: '/listings/my',
        builder: (context, state) => const MyListingsScreen(),
      ),
      GoRoute(
        path: '/listings/:id',
        builder: (context, state) => ListingDetailScreen(listingId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/jobs/board',
        builder: (context, state) => const HaulerJobBoardScreen(),
      ),
      GoRoute(
        path: '/jobs/:id',
        builder: (context, state) {
          final jobId = state.pathParameters['id'] ?? '';
          final job = state.extra as Job?;
          return JobDetailScreen(jobId: jobId, initialJob: job);
        },
      ),
      GoRoute(
        path: '/settings/notifications',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/billing',
        builder: (context, state) => const BillingScreen(),
      ),
      GoRoute(
        path: '/jobs/:jobId/manifest',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          return ManifestScreen(
            job: extras['job'] as Job,
            hostName: extras['hostName'] as String,
            haulerName: extras['haulerName'] as String,
            hostCompany: extras['hostCompany'] as String?,
            haulerCompany: extras['haulerCompany'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/jobs/:jobId/review',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          return ReviewScreen(
            jobId: state.pathParameters['jobId'] ?? '',
            revieweeUid: extras['revieweeUid'] as String,
            revieweeName: extras['revieweeName'] as String,
          );
        },
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/messages',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/chat/:chatId',
        builder: (context, state) => ChatScreen(
          chatId: state.pathParameters['chatId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationCenterScreen(),
      ),
    ],
  );
});
