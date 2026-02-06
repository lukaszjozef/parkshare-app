import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_client.dart';

// Auth state provider
final authStateProvider = StreamProvider<AuthState>((ref) {
  return SupabaseClientManager.client.auth.onAuthStateChange;
});

// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  return SupabaseClientManager.client.auth.currentUser;
});

// User profile with approval status
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final client = SupabaseClientManager.client;
  final user = client.auth.currentUser;
  if (user == null) return null;

  final profile = await client
      .from('users')
      .select()
      .eq('auth_id', user.id)
      .maybeSingle();

  return profile;
});

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthService {
  final _client = SupabaseClientManager.client;

  // Send magic link to email
  Future<void> sendMagicLink(String email) async {
    await _client.auth.signInWithOtp(
      email: email,
      emailRedirectTo: 'https://lukaszjozef.github.io/parkshare-app/',
    );
  }

  // Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Get current session
  Session? get currentSession => _client.auth.currentSession;

  // Check if user is logged in
  bool get isLoggedIn => _client.auth.currentUser != null;

  // Create or update user profile in our users table
  Future<void> upsertUserProfile({
    required String email,
    String? name,
    String? building,
    String? apartmentNumber,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('users').upsert({
      'auth_id': user.id,
      'email': email,
      'name': name,
      'building': building,
      'apartment_number': apartmentNumber,
    }, onConflict: 'auth_id');
  }

  // Get user profile from our users table
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('users')
        .select()
        .eq('auth_id', user.id)
        .maybeSingle();

    return response;
  }

  // Ensure user exists in our users table (call after login)
  Future<void> ensureUserExists() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    // Check if user already exists
    final existing = await _client
        .from('users')
        .select('id')
        .eq('auth_id', user.id)
        .maybeSingle();

    if (existing == null) {
      // Create user entry
      await _client.from('users').insert({
        'auth_id': user.id,
        'email': user.email,
      });
    }
  }
}
