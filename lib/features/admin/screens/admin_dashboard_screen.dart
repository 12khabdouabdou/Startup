import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../repositories/admin_repository.dart';

import '../../auth/repositories/auth_repository.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingUsersAsync = ref.watch(pendingUsersProvider);
    const forestGreen = Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        title: const Text('Operations Hub', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            tooltip: 'Sign Out',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: pendingUsersAsync.when(
        data: (users) {
          return CustomScrollView(
            slivers: [
              // Summary Stats
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: forestGreen,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: forestGreen.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shield_outlined, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text('SECURITY OVERVIEW', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${users.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900, height: 1),
                        ),
                        const Text(
                          'Pending Verifications',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Review requested for new network members.',
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text('VERIFICATION QUEUE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                ),
              ),

              if (users.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                          child: Icon(Icons.verified_user_outlined, size: 48, color: Colors.grey[300]),
                        ),
                        const SizedBox(height: 24),
                        const Text('All caught up!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('No pending verifications found.', style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final user = users[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[100]!),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(color: forestGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                              alignment: Alignment.center,
                              child: Icon(
                                user.role == UserRole.hauler ? Icons.local_shipping_outlined : Icons.business_outlined,
                                color: forestGreen,
                              ),
                            ),
                            title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${user.role.name.toUpperCase()} • ${user.phone ?? "No Phone"}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                            onTap: () => context.push('/admin/user/${user.id}', extra: user),
                          ),
                        );
                      },
                      childCount: users.length,
                    ),
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: forestGreen)),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
