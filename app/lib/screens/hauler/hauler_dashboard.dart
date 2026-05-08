import 'package:flutter/material.dart';
import 'available_jobs_screen.dart';
import 'my_jobs_screen.dart';

class HaulerDashboard extends StatelessWidget {
  const HaulerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hauler Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildCard(Icons.local_shipping, 'Available Jobs', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AvailableJobsScreen()))),
            _buildCard(Icons.history, 'My Jobs', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyJobsScreen()))),
            _buildCard(Icons.payment, 'Payments', () {}),
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
