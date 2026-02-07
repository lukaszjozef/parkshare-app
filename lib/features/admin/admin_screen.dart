import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'admin_provider.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdminAsync = ref.watch(isAdminProvider);

    return isAdminAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        body: Center(child: Text('Błąd: $err')),
      ),
      data: (isAdmin) {
        if (!isAdmin) {
          return Scaffold(
            appBar: AppBar(title: const Text('Brak dostępu')),
            body: const Center(
              child: Text('Nie masz uprawnień administratora.'),
            ),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Panel admina'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/'),
              ),
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Oczekujące'),
                  Tab(text: 'Wszyscy'),
                ],
              ),
            ),
            body: const TabBarView(
              children: [
                _PendingTab(),
                _AllUsersTab(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PendingTab extends ConsumerWidget {
  const _PendingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingApprovalsProvider);

    return pendingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Błąd: $err')),
      data: (users) {
        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green[300]),
                const SizedBox(height: 16),
                const Text(
                  'Brak oczekujących',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Wszyscy użytkownicy zostali zaakceptowani',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(pendingApprovalsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return _UserCard(user: user, showActions: true);
            },
          ),
        );
      },
    );
  }
}

class _AllUsersTab extends ConsumerWidget {
  const _AllUsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);

    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Błąd: $err')),
      data: (users) {
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(allUsersProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return _UserCard(user: user, showActions: false);
            },
          ),
        );
      },
    );
  }
}

class _UserCard extends ConsumerWidget {
  final PendingUser user;
  final bool showActions;

  const _UserCard({required this.user, required this.showActions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: user.isAdmin
                      ? Colors.purple
                      : user.isApproved
                          ? const Color(0xFF10B981)
                          : Colors.orange,
                  child: Text(
                    user.displayName[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            user.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (user.isAdmin) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ADMIN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        user.email,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (!showActions && !user.isAdmin)
                  GestureDetector(
                    onTap: () => _toggleStatus(context, ref, user),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: user.isApproved
                            ? const Color(0xFF10B981).withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            user.isApproved ? 'Aktywny' : 'Nieaktywny',
                            style: TextStyle(
                              color: user.isApproved
                                  ? const Color(0xFF10B981)
                                  : Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.swap_horiz,
                            size: 14,
                            color: user.isApproved
                                ? const Color(0xFF10B981)
                                : Colors.orange,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.apartment, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  user.locationInfo,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const Spacer(),
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  user.createdAtText,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
            if (showActions && !user.isAdmin) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _reject(context, ref, user),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Odrzuć'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _approve(context, ref, user),
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
          ],
        ),
      ),
    );
  }

  void _toggleStatus(BuildContext context, WidgetRef ref, PendingUser user) async {
    final service = ref.read(adminServiceProvider);
    if (user.isApproved) {
      await service.revokeApproval(user.id);
    } else {
      await service.approveUser(user.id);
    }
    ref.invalidate(pendingApprovalsProvider);
    ref.invalidate(allUsersProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            user.isApproved
                ? '${user.displayName} dezaktywowany'
                : '${user.displayName} aktywowany',
          ),
          backgroundColor: user.isApproved ? Colors.orange : const Color(0xFF10B981),
        ),
      );
    }
  }

  void _approve(BuildContext context, WidgetRef ref, PendingUser user) async {
    final service = ref.read(adminServiceProvider);
    await service.approveUser(user.id);
    ref.invalidate(pendingApprovalsProvider);
    ref.invalidate(allUsersProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.displayName} zaakceptowany'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  void _reject(BuildContext context, WidgetRef ref, PendingUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Odrzucić użytkownika?'),
        content: Text(
          'Czy na pewno chcesz odrzucić ${user.displayName}?\n'
          'Konto zostanie usunięte.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Odrzuć'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final service = ref.read(adminServiceProvider);
      await service.rejectUser(user.id);
      ref.invalidate(pendingApprovalsProvider);
      ref.invalidate(allUsersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Użytkownik odrzucony')),
        );
      }
    }
  }
}
