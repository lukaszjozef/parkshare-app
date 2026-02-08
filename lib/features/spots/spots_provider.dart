import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_client.dart';

// User's parking spots provider
final userSpotsProvider = FutureProvider<List<ParkingSpot>>((ref) async {
  final client = SupabaseClientManager.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  // First get user's internal ID
  final userProfile = await client
      .from('users')
      .select('id')
      .eq('auth_id', user.id)
      .maybeSingle();

  if (userProfile == null) return [];

  final response = await client
      .from('parking_spots')
      .select()
      .eq('owner_id', userProfile['id'])
      .order('created_at', ascending: false);

  return (response as List)
      .map((spot) => ParkingSpot.fromJson(spot))
      .toList();
});

// Spots service provider
final spotsServiceProvider = Provider<SpotsService>((ref) {
  return SpotsService();
});

class SpotsService {
  final _client = SupabaseClientManager.client;

  Future<String?> _getUserId() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final profile = await _client
        .from('users')
        .select('id')
        .eq('auth_id', user.id)
        .maybeSingle();

    return profile?['id'];
  }

  Future<void> addSpot({
    required String building,
    required String spotNumber,
    String? level,
    String? description,
  }) async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('User not found');

    // Pad to 3 digits: 1 → 001, 67 → 067
    final paddedNumber = spotNumber.padLeft(3, '0');

    await _client.from('parking_spots').insert({
      'owner_id': userId,
      'building': building,
      'spot_number': paddedNumber,
      'level': level,
      'description': description,
      'is_active': true,
    });
  }

  Future<void> updateSpot({
    required String spotId,
    required String building,
    required String spotNumber,
    String? level,
    String? description,
  }) async {
    final paddedNumber = spotNumber.padLeft(3, '0');

    await _client.from('parking_spots').update({
      'building': building,
      'spot_number': paddedNumber,
      'level': level,
      'description': description,
    }).eq('id', spotId);
  }

  Future<void> deleteSpot(String spotId) async {
    await _client.from('parking_spots').delete().eq('id', spotId);
  }

  Future<void> toggleSpotActive(String spotId, bool isActive) async {
    await _client.from('parking_spots').update({
      'is_active': isActive,
    }).eq('id', spotId);
  }
}

class ParkingSpot {
  final String id;
  final String ownerId;
  final String building;
  final String spotNumber;
  final String? level;
  final String? description;
  final String? photoUrl;
  final bool isActive;
  final DateTime createdAt;

  ParkingSpot({
    required this.id,
    required this.ownerId,
    required this.building,
    required this.spotNumber,
    this.level,
    this.description,
    this.photoUrl,
    required this.isActive,
    required this.createdAt,
  });

  /// Masked number: first digit visible, rest replaced with *
  /// e.g. "142" → "1**", "067" → "0**"
  String get maskedSpotNumber {
    if (spotNumber.isEmpty) return '***';
    return spotNumber[0] + '*' * (spotNumber.length - 1);
  }

  factory ParkingSpot.fromJson(Map<String, dynamic> json) {
    return ParkingSpot(
      id: json['id'],
      ownerId: json['owner_id'],
      building: json['building'],
      spotNumber: json['spot_number'],
      level: json['level'],
      description: json['description'],
      photoUrl: json['photo_url'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
