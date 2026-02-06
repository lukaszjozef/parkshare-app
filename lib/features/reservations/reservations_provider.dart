import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_client.dart';

// My reservations (as requester)
final myReservationsProvider = FutureProvider<List<Reservation>>((ref) async {
  final client = SupabaseClientManager.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  final userProfile = await client
      .from('users')
      .select('id')
      .eq('auth_id', user.id)
      .maybeSingle();
  if (userProfile == null) return [];

  final response = await client
      .from('reservations')
      .select('''
        *,
        parking_spots!inner (
          *,
          users!inner (name, building)
        )
      ''')
      .eq('requester_id', userProfile['id'])
      .order('created_at', ascending: false);

  return (response as List).map((r) => Reservation.fromJson(r)).toList();
});

// Requests for my spots (as owner)
final incomingRequestsProvider = FutureProvider<List<Reservation>>((ref) async {
  final client = SupabaseClientManager.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  final userProfile = await client
      .from('users')
      .select('id')
      .eq('auth_id', user.id)
      .maybeSingle();
  if (userProfile == null) return [];

  // Get my spots
  final mySpots = await client
      .from('parking_spots')
      .select('id')
      .eq('owner_id', userProfile['id']);

  if ((mySpots as List).isEmpty) return [];

  final spotIds = mySpots.map((s) => s['id']).toList();

  final response = await client
      .from('reservations')
      .select('''
        *,
        parking_spots!inner (*),
        users!inner (name, building, apartment_number)
      ''')
      .inFilter('spot_id', spotIds)
      .order('created_at', ascending: false);

  return (response as List).map((r) => Reservation.fromJsonWithRequester(r)).toList();
});

// Reservation service
final reservationServiceProvider = Provider<ReservationService>((ref) {
  return ReservationService();
});

class ReservationService {
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

  Future<void> createReservation({
    required String spotId,
    required String availabilityId,
    required DateTime startsAt,
    required DateTime endsAt,
    String? message,
  }) async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('User not found');

    await _client.from('reservations').insert({
      'spot_id': spotId,
      'availability_id': availabilityId,
      'requester_id': userId,
      'starts_at': startsAt.toIso8601String(),
      'ends_at': endsAt.toIso8601String(),
      'status': 'pending',
      'message': message,
    });
  }

  Future<void> acceptReservation(String reservationId) async {
    await _client.from('reservations').update({
      'status': 'accepted',
    }).eq('id', reservationId);
  }

  Future<void> rejectReservation(String reservationId, {String? reason}) async {
    await _client.from('reservations').update({
      'status': 'rejected',
      'rejection_reason': reason,
    }).eq('id', reservationId);
  }

  Future<void> cancelReservation(String reservationId) async {
    await _client.from('reservations').update({
      'status': 'cancelled',
    }).eq('id', reservationId);
  }
}

class Reservation {
  final String id;
  final String spotId;
  final String requesterId;
  final DateTime startsAt;
  final DateTime endsAt;
  final String status;
  final String? message;
  final String? rejectionReason;
  final DateTime createdAt;

  // Spot info
  final String? spotNumber;
  final String? spotBuilding;
  final String? spotLevel;

  // Owner info (when viewing as requester)
  final String? ownerName;

  // Requester info (when viewing as owner)
  final String? requesterName;
  final String? requesterBuilding;
  final String? requesterApartment;

  Reservation({
    required this.id,
    required this.spotId,
    required this.requesterId,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    this.message,
    this.rejectionReason,
    required this.createdAt,
    this.spotNumber,
    this.spotBuilding,
    this.spotLevel,
    this.ownerName,
    this.requesterName,
    this.requesterBuilding,
    this.requesterApartment,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    final spot = json['parking_spots'];
    final owner = spot?['users'];

    return Reservation(
      id: json['id'],
      spotId: json['spot_id'],
      requesterId: json['requester_id'],
      startsAt: DateTime.parse(json['starts_at']),
      endsAt: DateTime.parse(json['ends_at']),
      status: json['status'],
      message: json['message'],
      rejectionReason: json['rejection_reason'],
      createdAt: DateTime.parse(json['created_at']),
      spotNumber: spot?['spot_number'],
      spotBuilding: spot?['building'],
      spotLevel: spot?['level'],
      ownerName: owner?['name'],
    );
  }

  factory Reservation.fromJsonWithRequester(Map<String, dynamic> json) {
    final spot = json['parking_spots'];
    final requester = json['users'];

    return Reservation(
      id: json['id'],
      spotId: json['spot_id'],
      requesterId: json['requester_id'],
      startsAt: DateTime.parse(json['starts_at']),
      endsAt: DateTime.parse(json['ends_at']),
      status: json['status'],
      message: json['message'],
      rejectionReason: json['rejection_reason'],
      createdAt: DateTime.parse(json['created_at']),
      spotNumber: spot?['spot_number'],
      spotBuilding: spot?['building'],
      spotLevel: spot?['level'],
      requesterName: requester?['name'],
      requesterBuilding: requester?['building'],
      requesterApartment: requester?['apartment_number'],
    );
  }

  String get statusText {
    switch (status) {
      case 'pending': return 'Oczekuje';
      case 'accepted': return 'Zaakceptowana';
      case 'rejected': return 'Odrzucona';
      case 'cancelled': return 'Anulowana';
      case 'completed': return 'Zakończona';
      default: return status;
    }
  }

  String get timeRangeText {
    final startTime = '${startsAt.hour.toString().padLeft(2, '0')}:${startsAt.minute.toString().padLeft(2, '0')}';
    final endTime = '${endsAt.hour.toString().padLeft(2, '0')}:${endsAt.minute.toString().padLeft(2, '0')}';
    return '${startsAt.day}.${startsAt.month} $startTime - $endTime';
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
}
