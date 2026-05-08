import 'package:flutter/material.dart';
import 'user_management_screen.dart';
import 'payments_overview_screen.dart';
import 'audit_log_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildCard(Icons.people, 'Users', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementScreen()))),
            _buildCard(Icons.payment, 'Payments', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentsOverviewScreen()))),
            _buildCard(Icons.article, 'Audit Log', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuditLogScreen()))),
            _buildCard(Icons.settings, 'Commission', () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(IconData icon, String label, VoidCallback onTap) {
    return Card(
      child: InkWell(onTap: onTap, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 48), const SizedBox(height: 8), Text(label)]))),
    );
  }
}
