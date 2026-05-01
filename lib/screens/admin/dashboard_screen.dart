import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:waste_logistics/models/order.dart';
import 'package:waste_logistics/models/user.dart';
import 'package:waste_logistics/services/auth_service.dart';
import 'package:waste_logistics/services/order_service.dart';
import 'package:waste_logistics/theme/app_theme.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService();
});

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authService = ref.read(authServiceProvider);
              await authService.signOut();
              if (mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _OverviewTab(),
          _OrdersTab(),
          _UsersTab(),
          _AnalyticsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard Overview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _StatCard(
                icon: Icons.shopping_cart,
                title: 'Total Orders',
                value: '0',
                color: AppTheme.primaryColor,
                onTap: () {},
              ),
              _StatCard(
                icon: Icons.people,
                title: 'Total Users',
                value: '0',
                color: AppTheme.secondaryColor,
                onTap: () {},
              ),
              _StatCard(
                icon: Icons.local_shipping,
                title: 'Active Drivers',
                value: '0',
                color: AppTheme.accentColor,
                onTap: () {},
              ),
              _StatCard(
                icon: Icons.recycling,
                title: 'Active Recyclers',
                value: '0',
                color: AppTheme.warningColor,
                onTap: () {},
              ),
              _StatCard(
                icon: Icons.attach_money,
                title: 'Revenue',
                value: '\$0.00',
                color: AppTheme.successColor,
                onTap: () {},
              ),
              _StatCard(
                icon: Icons.pending,
                title: 'Pending Orders',
                value: '0',
                color: Colors.orange,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                _ActivityItem(
                  icon: Icons.shopping_cart,
                  title: 'New order placed',
                  subtitle: '2 minutes ago',
                  color: AppTheme.primaryColor,
                ),
                Divider(),
                _ActivityItem(
                  icon: Icons.person_add,
                  title: 'New user registered',
                  subtitle: '15 minutes ago',
                  color: AppTheme.secondaryColor,
                ),
                Divider(),
                _ActivityItem(
                  icon: Icons.check_circle,
                  title: 'Order completed',
                  subtitle: '1 hour ago',
                  color: AppTheme.successColor,
                ),
                Divider(),
                _ActivityItem(
                  icon: Icons.local_shipping,
                  title: 'Driver went online',
                  subtitle: '2 hours ago',
                  color: AppTheme.accentColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}

class _OrdersTab extends ConsumerWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Pending'),
              Tab(text: 'Confirmed'),
              Tab(text: 'In Progress'),
              Tab(text: 'Completed'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _OrdersList(statusFilter: null),
                _OrdersList(statusFilter: OrderStatus.pending),
                _OrdersList(statusFilter: OrderStatus.confirmed),
                _OrdersList(statusFilter: OrderStatus.inProgress),
                _OrdersList(statusFilter: OrderStatus.completed),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersList extends ConsumerWidget {
  final OrderStatus? statusFilter;

  const _OrdersList({this.statusFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<Order>>(
      stream: ref.read(orderServiceProvider).watchCustomerOrders(''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No orders found',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        final orders = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            return _OrderCard(order: orders[index]);
          },
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getStatusColor(order.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getStatusIcon(order.status),
            color: _getStatusColor(order.status),
          ),
        ),
        title: Text(
          'Order #${order.id.substring(0, 8)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${order.wasteType.name} • ${_formatDate(order.scheduledDate)}',
        ),
        trailing: Chip(
          label: Text(
            _getStatusText(order.status),
            style: const TextStyle(fontSize: 12),
          ),
          backgroundColor: _getStatusColor(order.status).withOpacity(0.1),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(
                  icon: Icons.person,
                  label: 'Customer',
                  value: order.customerName,
                ),
                const SizedBox(height: 8),
                _DetailRow(
                  icon: Icons.phone,
                  label: 'Phone',
                  value: order.customerPhone,
                ),
                const SizedBox(height: 8),
                _DetailRow(
                  icon: Icons.location_on,
                  label: 'Pickup Address',
                  value: order.pickupAddress,
                ),
                const SizedBox(height: 8),
                _DetailRow(
                  icon: Icons.scale,
                  label: 'Weight',
                  value: '${order.estimatedWeight.toStringAsFixed(1)} kg',
                ),
                const SizedBox(height: 8),
                _DetailRow(
                  icon: Icons.attach_money,
                  label: 'Price',
                  value: '\$${order.estimatedPrice.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        child: const Text('View Details'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        child: const Text('Manage'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.inProgress:
        return Colors.purple;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.pending;
      case OrderStatus.confirmed:
        return Icons.check_circle;
      case OrderStatus.inProgress:
        return Icons.local_shipping;
      case OrderStatus.completed:
        return Icons.done_all;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusText(OrderStatus status) {
    return status.name[0].toUpperCase() + status.name.substring(1);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _UsersTab extends ConsumerWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'All Users'),
              Tab(text: 'Customers'),
              Tab(text: 'Drivers'),
              Tab(text: 'Recyclers'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _UsersList(userTypeFilter: null),
                _UsersList(userTypeFilter: UserType.customer),
                _UsersList(userTypeFilter: UserType.driver),
                _UsersList(userTypeFilter: UserType.recycler),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UsersList extends ConsumerWidget {
  final UserType? userTypeFilter;

  const _UsersList({this.userTypeFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'User management coming soon',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsTab extends ConsumerWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analytics',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Statistics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StatRow(
                    label: 'Total Orders',
                    value: '0',
                  ),
                  const Divider(),
                  _StatRow(
                    label: 'Completed Orders',
                    value: '0',
                  ),
                  const Divider(),
                  _StatRow(
                    label: 'Pending Orders',
                    value: '0',
                  ),
                  const Divider(),
                  _StatRow(
                    label: 'Cancelled Orders',
                    value: '0',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Revenue Statistics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StatRow(
                    label: 'Total Revenue',
                    value: '\$0.00',
                  ),
                  const Divider(),
                  _StatRow(
                    label: 'This Month',
                    value: '\$0.00',
                  ),
                  const Divider(),
                  _StatRow(
                    label: 'This Week',
                    value: '\$0.00',
                  ),
                  const Divider(),
                  _StatRow(
                    label: 'Today',
                    value: '\$0.00',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'User Statistics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StatRow(
                    label: 'Total Users',
                    value: '0',
                  ),
                  const Divider(),
                  _StatRow(
                    label: 'Active Users',
                    value: '0',
                  ),
                  const Divider(),
                  _StatRow(
                    label: 'New Users (This Month)',
                    value: '0',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
