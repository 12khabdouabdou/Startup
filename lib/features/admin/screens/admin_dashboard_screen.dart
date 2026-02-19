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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: pendingUsersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('No pending users.'));
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(child: Text(user.role.name[0].toUpperCase())),
                title: Text(user.displayName ?? 'Unknown User'),
                subtitle: Text('${user.role.name} • ${user.phone ?? 'No phone'}'),
                onTap: () {
                  context.push('/admin/user/${user.id}', extra: user);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
