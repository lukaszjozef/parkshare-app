import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'spots_provider.dart';

class SpotsScreen extends ConsumerWidget {
  const SpotsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spotsAsync = ref.watch(userSpotsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moje miejsca'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: spotsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Błąd: $err')),
        data: (spots) {
          if (spots.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildSpotsList(context, ref, spots);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/spots/add'),
        icon: const Icon(Icons.add),
        label: const Text('Dodaj miejsce'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_parking,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            const Text(
              'Nie masz jeszcze miejsc',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dodaj swoje miejsce parkingowe,\naby móc je udostępniać sąsiadom',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go('/spots/add'),
              icon: const Icon(Icons.add),
              label: const Text('Dodaj pierwsze miejsce'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpotsList(
    BuildContext context,
    WidgetRef ref,
    List<ParkingSpot> spots,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: spots.length,
      itemBuilder: (context, index) {
        final spot = spots[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: spot.isActive
                    ? const Color(0xFF2563EB).withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.local_parking,
                color: spot.isActive
                    ? const Color(0xFF2563EB)
                    : Colors.grey,
              ),
            ),
            title: Text(
              'Miejsce ${spot.spotNumber}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${spot.building}${spot.level != null ? ' • Poziom ${spot.level}' : ''}',
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'share') {
                  context.go('/spots/share/${spot.id}');
                } else if (value == 'edit') {
                  context.go('/spots/edit/${spot.id}');
                } else if (value == 'toggle') {
                  final service = ref.read(spotsServiceProvider);
                  await service.toggleSpotActive(spot.id, !spot.isActive);
                  ref.invalidate(userSpotsProvider);
                } else if (value == 'delete') {
                  _showDeleteDialog(context, ref, spot);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share, size: 20, color: Color(0xFF10B981)),
                      SizedBox(width: 8),
                      Text('Udostępnij', style: TextStyle(color: Color(0xFF10B981))),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edytuj'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(
                        spot.isActive ? Icons.visibility_off : Icons.visibility,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(spot.isActive ? 'Dezaktywuj' : 'Aktywuj'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Usuń', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    ParkingSpot spot,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuń miejsce?'),
        content: Text(
          'Czy na pewno chcesz usunąć miejsce ${spot.spotNumber}?\n'
          'Ta operacja jest nieodwracalna.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () async {
              final service = ref.read(spotsServiceProvider);
              await service.deleteSpot(spot.id);
              ref.invalidate(userSpotsProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text(
              'Usuń',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
