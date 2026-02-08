import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'reservations_provider.dart';

class ReservationsScreen extends ConsumerWidget {
  const ReservationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Rezerwacje'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Moje rezerwacje'),
              Tab(text: 'Prośby do mnie'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _MyReservationsTab(),
            _IncomingRequestsTab(),
          ],
        ),
      ),
    );
  }
}

class _MyReservationsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationsAsync = ref.watch(myReservationsProvider);

    return reservationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Błąd: $err')),
      data: (reservations) {
        if (reservations.isEmpty) {
          return _buildEmpty(
            icon: Icons.calendar_today,
            title: 'Brak rezerwacji',
            subtitle: 'Nie masz jeszcze żadnych rezerwacji.\nZnajdź wolne miejsce i zarezerwuj!',
          );
        }
        return _buildList(context, ref, reservations, isOwnerView: false);
      },
    );
  }
}

class _IncomingRequestsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(incomingRequestsProvider);

    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Błąd: $err')),
      data: (requests) {
        if (requests.isEmpty) {
          return _buildEmpty(
            icon: Icons.inbox,
            title: 'Brak próśb',
            subtitle: 'Nikt jeszcze nie poprosił o Twoje miejsce.\nUdostępnij je, aby inni mogli rezerwować!',
          );
        }
        return _buildList(context, ref, requests, isOwnerView: true);
      },
    );
  }
}

Widget _buildEmpty({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    ),
  );
}

Widget _buildList(
  BuildContext context,
  WidgetRef ref,
  List<Reservation> reservations, {
  required bool isOwnerView,
}) {
  return ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: reservations.length,
    itemBuilder: (context, index) {
      final r = reservations[index];
      return _ReservationCard(
        reservation: r,
        isOwnerView: isOwnerView,
      );
    },
  );
}

class _ReservationCard extends ConsumerWidget {
  final Reservation reservation;
  final bool isOwnerView;

  const _ReservationCard({
    required this.reservation,
    required this.isOwnerView,
  });

  Color get _statusColor {
    switch (reservation.status) {
      case 'pending': return Colors.orange;
      case 'accepted': return const Color(0xFF10B981);
      case 'rejected': return Colors.red;
      case 'cancelled': return Colors.grey;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.local_parking, color: _statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Miejsce ${reservation.displaySpotNumber}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        reservation.spotBuilding ?? '',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    reservation.statusText,
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Details
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  reservation.timeRangeText,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  isOwnerView
                      ? '${reservation.requesterName ?? 'Anonim'} (${reservation.requesterBuilding ?? ''} m. ${reservation.requesterApartment ?? ''})'
                      : reservation.ownerName ?? 'Właściciel',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),

            if (reservation.message != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.message, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reservation.message!,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Actions for owner
            if (isOwnerView && reservation.isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _reject(context, ref),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Odrzuć'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _accept(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Akceptuj'),
                    ),
                  ),
                ],
              ),
            ],

            // Cancel for requester
            if (!isOwnerView && reservation.isPending) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _cancel(context, ref),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Anuluj prośbę'),
                ),
              ),
            ],

            // Chat button for accepted reservations
            if (reservation.isAccepted) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final otherName = isOwnerView
                        ? reservation.requesterName ?? 'Gość'
                        : reservation.ownerName ?? 'Właściciel';
                    context.go('/chat/${reservation.id}?name=$otherName');
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('Otwórz chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _accept(BuildContext context, WidgetRef ref) async {
    final service = ref.read(reservationServiceProvider);
    await service.acceptReservation(reservation.id);
    ref.invalidate(incomingRequestsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rezerwacja zaakceptowana!'), backgroundColor: Color(0xFF10B981)),
      );
    }
  }

  void _reject(BuildContext context, WidgetRef ref) async {
    final service = ref.read(reservationServiceProvider);
    await service.rejectReservation(reservation.id);
    ref.invalidate(incomingRequestsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rezerwacja odrzucona'), backgroundColor: Colors.orange),
      );
    }
  }

  void _cancel(BuildContext context, WidgetRef ref) async {
    final service = ref.read(reservationServiceProvider);
    await service.cancelReservation(reservation.id);
    ref.invalidate(myReservationsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prośba anulowana')),
      );
    }
  }
}
