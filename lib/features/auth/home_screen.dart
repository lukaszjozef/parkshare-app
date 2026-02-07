import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_provider.dart';
import '../reservations/reservations_provider.dart';
import '../spots/availability_provider.dart';
import '../admin/admin_provider.dart';
import '../../core/push_notifications.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _pushSubscribed = true; // assume subscribed until checked
  bool _pushSupported = false;
  bool _pushLoading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(authServiceProvider).ensureUserExists();
      if (kIsWeb) {
        _pushSupported = PushNotificationService.isSupported;
        if (_pushSupported) {
          _pushSubscribed = await PushNotificationService.isSubscribed();
          if (mounted) setState(() {});
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);
    final user = ref.watch(currentUserProvider);
    final userProfile = ref.watch(userProfileProvider);
    final incomingRequests = ref.watch(incomingRequestsProvider);
    final availableSpots = ref.watch(availableSpotsProvider);
    final isAdmin = ref.watch(isAdminProvider);

    final isAdminUser = isAdmin.when(
      data: (v) => v,
      loading: () => false,
      error: (_, __) => false,
    );

    final isApproved = userProfile.when(
      data: (p) => p?['is_approved'] == true,
      loading: () => true,
      error: (_, __) => true,
    );

    // Count pending requests
    final pendingCount = incomingRequests.when(
      data: (list) => list.where((r) => r.isPending).length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    // Count available spots
    final availableCount = availableSpots.when(
      data: (list) => list.length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('ParkShareG181'),
        actions: [
          if (isAdminUser)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () => context.go('/admin'),
              tooltip: 'Panel admina',
            ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.go('/profile'),
            tooltip: 'Mój profil',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            tooltip: 'Wyloguj',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(incomingRequestsProvider);
          ref.invalidate(availableSpotsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Inactive account banner
              if (!isApproved)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Twoje konto jest nieaktywne. Skontaktuj się z administratorem.',
                          style: TextStyle(color: Colors.orange.shade800),
                        ),
                      ),
                    ],
                  ),
                ),

              // Welcome card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.waving_hand,
                        size: 40,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cześć${user?.email != null ? ', ${user!.email!.split('@')[0]}' : ''}!',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Push notification banner
              if (_pushSupported && !_pushSubscribed)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF2563EB).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.notifications_active,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Włącz powiadomienia',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            Text(
                              'Dostaniesz info gdy pojawi się wolne miejsce',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      _pushLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : TextButton(
                              onPressed: () async {
                                setState(() => _pushLoading = true);
                                final ok =
                                    await PushNotificationService.subscribe();
                                if (mounted) {
                                  setState(() {
                                    _pushSubscribed = ok;
                                    _pushLoading = false;
                                  });
                                  if (ok) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Powiadomienia włączone!'),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text('Włącz'),
                            ),
                    ],
                  ),
                ),

              // Stats row
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.local_parking,
                      value: '$availableCount',
                      label: 'Wolnych miejsc',
                      color: const Color(0xFF10B981),
                      onTap: () => context.go('/search'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.notifications,
                      value: '$pendingCount',
                      label: 'Oczekujących',
                      color: pendingCount > 0 ? Colors.orange : Colors.grey,
                      onTap: () => context.go('/reservations'),
                      highlight: pendingCount > 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick actions
              const Text(
                'Co chcesz zrobić?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _buildActionCard(
                context,
                icon: Icons.local_parking,
                title: 'Moje miejsca',
                subtitle: isApproved
                    ? 'Dodaj i zarządzaj miejscami'
                    : 'Konto nieaktywne',
                color: const Color(0xFF2563EB),
                onTap: isApproved ? () => context.go('/spots') : null,
                disabled: !isApproved,
              ),
              const SizedBox(height: 10),

              _buildActionCard(
                context,
                icon: Icons.search,
                title: 'Szukaj miejsca',
                subtitle: isApproved
                    ? (availableCount > 0
                        ? '$availableCount miejsc dostępnych teraz'
                        : 'Znajdź wolne miejsce parkingowe')
                    : 'Konto nieaktywne',
                color: const Color(0xFF10B981),
                onTap: isApproved ? () => context.go('/search') : null,
                badge: isApproved && availableCount > 0 ? '$availableCount' : null,
                disabled: !isApproved,
              ),
              const SizedBox(height: 10),

              _buildActionCard(
                context,
                icon: Icons.calendar_today,
                title: 'Moje rezerwacje',
                subtitle: isApproved
                    ? (pendingCount > 0
                        ? '$pendingCount próśb czeka na odpowiedź'
                        : 'Sprawdź swoje rezerwacje')
                    : 'Konto nieaktywne',
                color: const Color(0xFFF59E0B),
                onTap: isApproved ? () => context.go('/reservations') : null,
                badge: isApproved && pendingCount > 0 ? '$pendingCount' : null,
                disabled: !isApproved,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
    String? badge,
    bool disabled = false,
  }) {
    final effectiveColor = disabled ? Colors.grey : color;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: disabled ? 0.5 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: effectiveColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: effectiveColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: effectiveColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (disabled)
                  Icon(Icons.lock, color: Colors.grey[400], size: 20)
                else
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool highlight;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: highlight ? color.withOpacity(0.1) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
