import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_client.dart';

// Check if current user is admin
final isAdminProvider = FutureProvider<bool>((ref) async {
  final client = SupabaseClientManager.client;
  final user = client.auth.currentUser;
  if (user == null) return false;

  final profile = await client
      .from('users')
      .select('is_admin')
      .eq('auth_id', user.id)
      .maybeSingle();

  return profile?['is_admin'] == true;
});

// Pending approvals list
final pendingApprovalsProvider = FutureProvider<List<PendingUser>>((ref) async {
  final client = SupabaseClientManager.client;

  final response = await client
      .from('users')
      .select()
      .eq('is_approved', false)
      .eq('is_admin', false)
      .order('created_at', ascending: false);

  return (response as List).map((u) => PendingUser.fromJson(u)).toList();
});

// All users list (for admin)
final allUsersProvider = FutureProvider<List<PendingUser>>((ref) async {
  final client = SupabaseClientManager.client;

  final response = await client
      .from('users')
      .select()
      .order('created_at', ascending: false);

  return (response as List).map((u) => PendingUser.fromJson(u)).toList();
});

// Admin service
final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService();
});

class AdminService {
  final _client = SupabaseClientManager.client;

  Future<void> approveUser(String userId) async {
    await _client.from('users').update({
      'is_approved': true,
    }).eq('id', userId);
  }

  Future<void> rejectUser(String userId) async {
    // Delete the user record
    await _client.from('users').delete().eq('id', userId);
  }

  Future<void> revokeApproval(String userId) async {
    await _client.from('users').update({
      'is_approved': false,
    }).eq('id', userId);
  }
}

class PendingUser {
  final String id;
  final String email;
  final String? name;
  final String? building;
  final String? apartmentNumber;
  final bool isApproved;
  final bool isAdmin;
  final DateTime createdAt;

  PendingUser({
    required this.id,
    required this.email,
    this.name,
    this.building,
    this.apartmentNumber,
    required this.isApproved,
    required this.isAdmin,
    required this.createdAt,
  });

  factory PendingUser.fromJson(Map<String, dynamic> json) {
    return PendingUser(
      id: json['id'],
      email: json['email'] ?? '',
      name: json['name'],
      building: json['building'],
      apartmentNumber: json['apartment_number'],
      isApproved: json['is_approved'] ?? false,
      isAdmin: json['is_admin'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get displayName => name ?? email.split('@').first;

  String get locationInfo {
    if (building == null) return 'Brak danych';
    return '$building${apartmentNumber != null ? ' m. $apartmentNumber' : ''}';
  }

  String get createdAtText {
    return '${createdAt.day}.${createdAt.month}.${createdAt.year}';
  }
}
