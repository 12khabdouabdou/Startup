import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/admin/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: Refresh data
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overview stats
              Text('Platform Overview', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildStatsGrid(context),
              const SizedBox(height: 24),

              // Quick actions
              Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildQuickActions(context),
              const SizedBox(height: 24),

              // Recent activity
              Text('Recent Activity', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildActivityFeed(),
              const SizedBox(height: 24),

              // Pending items
              Text('Pending Review', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildPendingItems(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          title: 'Total Users',
          value: '1,234',
          icon: Icons.people,
          color: Colors.blue,
        ),
        _StatCard(
          title: 'Active Listings',
          value: '89',
          icon: Icons.list,
          color: Colors.green,
        ),
        _StatCard(
          title: 'Bookings Today',
          value: '23',
          icon: Icons.local_shipping,
          color: Colors.orange,
        ),
        _StatCard(
          title: 'Revenue (Month)',
          value: '\$12.5K',
          icon: Icons.attach_money,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _QuickActionButton(
          icon: Icons.people,
          label: 'Users',
          onTap: () => context.push('/admin/users'),
        ),
        _QuickActionButton(
          icon: Icons.list,
          label: 'Listings',
          onTap: () => context.push('/admin/listings'),
        ),
        _QuickActionButton(
          icon: Icons.local_shipping,
          label: 'Bookings',
          onTap: () => context.push('/admin/bookings'),
        ),
        _QuickActionButton(
          icon: Icons.warning,
          label: 'Reports',
          onTap: () => context.push('/admin/reports'),
        ),
        _QuickActionButton(
          icon: Icons.analytics,
          label: 'Analytics',
          onTap: () => context.push('/admin/analytics'),
        ),
        _QuickActionButton(
          icon: Icons.verified,
          label: 'Certificates',
          onTap: () => context.push('/admin/certificates'),
        ),
      ],
    );
  }

  Widget _buildActivityFeed() {
    return Card(
      child: Column(
        children: [
          _ActivityItem(
            icon: Icons.person_add,
            text: 'New user registered',
            time: '2 mins ago',
          ),
          const Divider(height: 1),
          _ActivityItem(
            icon: Icons.check_circle,
            text: 'Booking #1234 completed',
            time: '5 mins ago',
          ),
          const Divider(height: 1),
          _ActivityItem(
            icon: Icons.warning,
            text: 'Report filed for listing #567',
            time: '12 mins ago',
          ),
          const Divider(height: 1),
          _ActivityItem(
            icon: Icons.business,
            text: 'New company verified',
            time: '25 mins ago',
          ),
        ],
      ),
    );
  }

  Widget _buildPendingItems(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _PendingItem(
            title: 'User Verification',
            description: '5 users awaiting verification',
            count: 5,
            onTap: () => context.push('/admin/users'),
          ),
          const Divider(height: 1),
          _PendingItem(
            title: 'Content Reports',
            description: '3 listings reported',
            count: 3,
            onTap: () => context.push('/admin/reports'),
          ),
          const Divider(height: 1),
          _PendingItem(
            title: 'Disputes',
            description: '2 disputes to resolve',
            count: 2,
            onTap: () => context.push('/admin/disputes'),
          ),
        ],
      ),
    );
  }
}

// Helper Widgets
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                Icon(Icons.more_horiz, color: Colors.grey.shade400),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final String time;

  const _ActivityItem({
    required this.icon,
    required this.text,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20, color: Colors.grey.shade600),
      title: Text(text),
      trailing: Text(
        time,
        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
      ),
    );
  }
}

class _PendingItem extends StatelessWidget {
  final String title;
  final String description;
  final int count;
  final VoidCallback onTap;

  const _PendingItem({
    required this.title,
    required this.description,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Row(
        children: [
          Expanded(child: Text(title)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      subtitle: Text(description),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
