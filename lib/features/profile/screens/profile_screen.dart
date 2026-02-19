import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/repositories/profile_repository.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../../core/models/mock_data.dart';
import '../../../core/models/app_user.dart';
import '../../notifications/widgets/notification_bell.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDocAsync = ref.watch(userDocProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: const [NotificationBell()],
      ),
      body: userDocAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('No profile data'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.green.withValues(alpha: 0.15),
                  child: Text(
                    (user.displayName ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.displayName ?? 'Unknown',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    user.role.name.toUpperCase(),
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
                if (user.reviewCount > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${user.rating.toStringAsFixed(1)} (${user.reviewCount} reviews)',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 32),

                // Profile Info Cards
                _ProfileTile(icon: Icons.business, label: 'Company', value: user.companyName ?? 'N/A'),
                _ProfileTile(icon: Icons.phone, label: 'Phone', value: user.phone ?? 'N/A'),
                _ProfileTile(icon: Icons.verified_user, label: 'Status', value: user.status.name.toUpperCase()),
                if (user.fleetSize != null)
                  _ProfileTile(icon: Icons.local_shipping, label: 'Fleet Size', value: '${user.fleetSize}'),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),

                // Settings Section
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit Profile'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/profile/edit'),
                ),
                ListTile(
                  leading: const Icon(Icons.chat_outlined),
                  title: const Text('Messages'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/messages'),
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notification Settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/notifications'),
                ),
                ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: const Text('Billing & Finance'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/billing'),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => ref.read(authRepositoryProvider).signOut(),
                    icon: const Icon(Icons.logout, color: Colors.orange),
                    label: const Text('Sign Out',
                        style: TextStyle(color: Colors.orange)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => _confirmDeleteAccount(context, ref, user.id),
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    label: const Text('Delete Account',
                        style: TextStyle(color: Colors.red)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                if (user.id.startsWith('mock-')) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('Debug Options', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.people_alt_outlined, color: Colors.purple),
                    title: const Text('Switch Mock Role', style: TextStyle(color: Colors.purple)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.purple),
                    tileColor: Colors.purple.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () => _showRoleSwitcher(context, ref),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showRoleSwitcher(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Mock Role', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.local_shipping),
              title: const Text('Hauler'),
              subtitle: const Text('View as a truck driver/owner'),
              onTap: () {
                ref.read(mockUserProvider.notifier).state = MockData.haulerUser;
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.landscape),
              title: const Text('Excavator'),
              subtitle: const Text('View as a site manager'),
              onTap: () {
                ref.read(mockUserProvider.notifier).state = MockData.excavatorUser;
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Developer'),
              subtitle: const Text('View as a project developer'),
              onTap: () {
                ref.read(mockUserProvider.notifier).state = MockData.developerUser;
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref, String uid) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
            'Are you sure you want to request account deletion? This action cannot be undone immediately. An admin will process your request within 30 days.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(profileRepositoryProvider)
                  .requestAccountDeletion(uid);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Account deletion request submitted.')),
                );
              }
            },
            child: const Text('Request Deletion',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        ],
      ),
    );
  }
}
