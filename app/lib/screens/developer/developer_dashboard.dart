import 'package:flutter/material.dart';
import 'developer_posts_screen.dart';
import 'developer_payments_screen.dart';

class DeveloperDashboard extends StatelessWidget {
  const DeveloperDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Developer Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildCard(Icons.add_box, 'Create Post', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostScreen()))),
            _buildCard(Icons.list, 'My Posts', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPostsScreen()))),
            _buildCard(Icons.payment, 'Payments', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeveloperPaymentsScreen()))),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(IconData icon, String label, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 48), const SizedBox(height: 8), Text(label)]),
      ),
    );
  }
}
