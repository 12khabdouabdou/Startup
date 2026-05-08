import 'package:flutter/material.dart';
import 'browse_waste_screen.dart';
import 'waste_map_screen.dart';
import 'my_selections_screen.dart';
import 'payment_screen.dart';
import '../shared/profile_screen.dart';

class RecyclerDashboard extends StatelessWidget {
  const RecyclerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recycler Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildCard(Icons.map, 'Browse Waste', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BrowseWasteScreen()))),
            _buildCard(Icons.location_on, 'Waste Map', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WasteMapScreen()))),
            _buildCard(Icons.shopping_cart, 'My Selections', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MySelectionsScreen()))),
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
