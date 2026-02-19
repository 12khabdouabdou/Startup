import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../profile/providers/profile_provider.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../../core/models/mock_data.dart';
import '../../../core/models/app_user.dart';
import '../../notifications/widgets/notification_bell.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDocAsync = ref.watch(userDocProvider);
    const forestGreen = Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        title: const Text('Account'),
        actions: const [NotificationBell(), SizedBox(width: 8)],
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: userDocAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('No profile data'));
          
          return SingleChildScrollView(
            child: Column(
              children: [
                // Premium Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: forestGreen.withOpacity(0.1), width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: forestGreen.withOpacity(0.05),
                              child: Text(
                                (user.displayName ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: forestGreen),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: forestGreen, shape: BoxShape.circle),
                            child: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        user.displayName ?? 'Professional User',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: forestGreen.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user.role.name.toUpperCase(),
                          style: const TextStyle(color: forestGreen, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                        ),
                      ),
                      if (user.reviewCount > 0) ...[
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _StatItem(label: 'RATING', value: user.rating.toStringAsFixed(1), icon: Icons.star_rounded, iconColor: Colors.amber[700]!),
                            Container(height: 24, width: 1, color: Colors.grey[200], margin: const EdgeInsets.symmetric(horizontal: 24)),
                            _StatItem(label: 'REVIEWS', value: '${user.reviewCount}', icon: Icons.comment_outlined, iconColor: Colors.grey[400]!),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Settings Sections
                _SettingsGroup(
                  title: 'PROFESSIONAL DETAILS',
                  children: [
                    _ProfileDetailRow(icon: Icons.business_outlined, label: 'Organization', value: user.companyName ?? 'Independent'),
                    _ProfileDetailRow(icon: Icons.phone_outlined, label: 'Direct Line', value: user.phone ?? 'Not set'),
                    if (user.fleetSize != null)
                      _ProfileDetailRow(icon: Icons.local_shipping_outlined, label: 'Fleet Assets', value: '${user.fleetSize} Heavy Vehicles'),
                  ],
                ),

                const SizedBox(height: 24),

                _SettingsGroup(
                  title: 'PREFERENCES',
                  children: [
                    if (user.role == UserRole.hauler)
                      _SettingsTile(
                        icon: Icons.local_shipping_outlined, 
                        title: 'Fleet Management', 
                        subtitle: 'Manage trucks & capacity',
                        onTap: () => context.push('/fleet'),
                      ),
                    _SettingsTile(
                      icon: Icons.notifications_none_rounded, 
                      title: 'Smart Alerts', 
                      subtitle: 'Radius & Event Triggers',
                      onTap: () => context.push('/settings/notifications'),
                    ),
                    _SettingsTile(
                      icon: Icons.account_balance_wallet_outlined, 
                      title: 'Billing & Finance', 
                      subtitle: 'Earnings & Manifests',
                      onTap: () => context.push('/billing'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                _SettingsGroup(
                  title: 'MOCK DEBUG TOOLS',
                  isVisible: user.id.startsWith('mock-'),
                  children: [
                    _SettingsTile(
                      icon: Icons.supervised_user_circle_outlined, 
                      title: 'Role Simulation', 
                      subtitle: 'Switch between user types',
                      onTap: () => _showRoleSwitcher(context, ref),
                      iconColor: Colors.purple,
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextButton.icon(
                    onPressed: () => ref.read(authRepositoryProvider).signOut(),
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: const Text('DISCONNECT ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red[700],
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: forestGreen)),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatItem({required this.label, required this.value, required this.icon, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 0.5)),
      ],
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool isVisible;

  const _SettingsGroup({required this.title, required this.children, this.isVisible = true});

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 1.2)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[100]!),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileDetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: Colors.grey[600]),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  const _SettingsTile({required this.icon, required this.title, required this.subtitle, required this.onTap, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon, color: iconColor ?? const Color(0xFF2E7D32)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[300]),
    );
  }
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
