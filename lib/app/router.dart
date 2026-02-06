import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/supabase_client.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/home_screen.dart';
import '../features/auth/onboarding_screen.dart';
import '../features/auth/pending_approval_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/spots/spots_screen.dart';
import '../features/spots/add_spot_screen.dart';
import '../features/spots/share_spot_screen.dart';
import '../features/spots/search_screen.dart';
import '../features/reservations/reservations_screen.dart';
import '../features/reservations/reserve_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/admin/admin_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final session = SupabaseClientManager.client.auth.currentSession;
    final isLoggedIn = session != null;
    final isLoggingIn = state.matchedLocation == '/login';
    final isPending = state.matchedLocation == '/pending';

    // If not logged in and not on login page, redirect to login
    if (!isLoggedIn && !isLoggingIn) {
      return '/login';
    }

    // If logged in and on login page, redirect to home
    if (isLoggedIn && isLoggingIn) {
      return '/';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/pending',
      builder: (context, state) => const PendingApprovalScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/spots',
      builder: (context, state) => const SpotsScreen(),
    ),
    GoRoute(
      path: '/spots/add',
      builder: (context, state) => const AddSpotScreen(),
    ),
    GoRoute(
      path: '/spots/share/:id',
      builder: (context, state) => ShareSpotScreen(
        spotId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: '/reservations',
      builder: (context, state) => const ReservationsScreen(),
    ),
    GoRoute(
      path: '/reserve/:id',
      builder: (context, state) => ReserveScreen(
        availabilityId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/chat/:id',
      builder: (context, state) => ChatScreen(
        reservationId: state.pathParameters['id']!,
        otherUserName: state.uri.queryParameters['name'] ?? 'Chat',
      ),
    ),
  ],
);

// Refresh router when auth state changes
class AuthNotifier extends ChangeNotifier {
  AuthNotifier() {
    SupabaseClientManager.client.auth.onAuthStateChange.listen((data) {
      notifyListeners();
    });
  }
}
