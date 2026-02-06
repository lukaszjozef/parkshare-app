import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_client.dart';
import 'spots_provider.dart';

// Available spots feed (all active availability)
final availableSpotsProvider = FutureProvider<List<AvailableSpot>>((ref) async {
  final client = SupabaseClientManager.client;

  final response = await client
      .from('availability')
      .select('''
        *,
        parking_spots!inner (
          *,
          users!inner (name, building, apartment_number)
        )
      ''')
      .gte('ends_at', DateTime.now().toIso8601String())
      .order('starts_at', ascending: true);

  return (response as List).map((item) => AvailableSpot.fromJson(item)).toList();
});

// User's spot availability
final spotAvailabilityProvider = FutureProvider.family<List<Availability>, String>((ref, spotId) async {
  final client = SupabaseClientManager.client;

  final response = await client
      .from('availability')
      .select()
      .eq('spot_id', spotId)
      .gte('ends_at', DateTime.now().toIso8601String())
      .order('starts_at', ascending: true);

  return (response as List).map((a) => Availability.fromJson(a)).toList();
});

// Availability service
final availabilityServiceProvider = Provider<AvailabilityService>((ref) {
  return AvailabilityService();
});

class AvailabilityService {
  final _client = SupabaseClientManager.client;

  // Quick share - available now for X hours
  Future<void> shareNow({
    required String spotId,
    int hours = 4,
    String? note,
  }) async {
    final now = DateTime.now();
    final endsAt = now.add(Duration(hours: hours));

    await _client.from('availability').insert({
      'spot_id': spotId,
      'starts_at': now.toIso8601String(),
      'ends_at': endsAt.toIso8601String(),
      'note': note,
      'is_recurring': false,
    });
  }

  // Share with custom time range
  Future<void> shareCustom({
    required String spotId,
    required DateTime startsAt,
    required DateTime endsAt,
    String? note,
  }) async {
    await _client.from('availability').insert({
      'spot_id': spotId,
      'starts_at': startsAt.toIso8601String(),
      'ends_at': endsAt.toIso8601String(),
      'note': note,
      'is_recurring': false,
    });
  }

  // Cancel availability
  Future<void> cancelAvailability(String availabilityId) async {
    await _client.from('availability').delete().eq('id', availabilityId);
  }
}

class Availability {
  final String id;
  final String spotId;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool isRecurring;
  final String? note;
  final DateTime createdAt;

  Availability({
    required this.id,
    required this.spotId,
    required this.startsAt,
    required this.endsAt,
    required this.isRecurring,
    this.note,
    required this.createdAt,
  });

  factory Availability.fromJson(Map<String, dynamic> json) {
    return Availability(
      id: json['id'],
      spotId: json['spot_id'],
      startsAt: DateTime.parse(json['starts_at']),
      endsAt: DateTime.parse(json['ends_at']),
      isRecurring: json['is_recurring'] ?? false,
      note: json['note'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  bool get isActiveNow {
    final now = DateTime.now();
    return now.isAfter(startsAt) && now.isBefore(endsAt);
  }

  String get timeRangeText {
    final startTime = '${startsAt.hour.toString().padLeft(2, '0')}:${startsAt.minute.toString().padLeft(2, '0')}';
    final endTime = '${endsAt.hour.toString().padLeft(2, '0')}:${endsAt.minute.toString().padLeft(2, '0')}';

    if (startsAt.day == endsAt.day) {
      return '$startTime - $endTime';
    }
    return '${startsAt.day}.${startsAt.month} $startTime - ${endsAt.day}.${endsAt.month} $endTime';
  }
}

class AvailableSpot {
  final Availability availability;
  final ParkingSpot spot;
  final String ownerName;
  final String ownerBuilding;

  AvailableSpot({
    required this.availability,
    required this.spot,
    required this.ownerName,
    required this.ownerBuilding,
  });

  factory AvailableSpot.fromJson(Map<String, dynamic> json) {
    final spotData = json['parking_spots'];
    final userData = spotData['users'];

    return AvailableSpot(
      availability: Availability.fromJson(json),
      spot: ParkingSpot.fromJson(spotData),
      ownerName: userData['name'] ?? 'Anonim',
      ownerBuilding: userData['building'] ?? '',
    );
  }
}
