import 'package:flutter/material.dart';

class DeveloperHome extends StatelessWidget {
  const DeveloperHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Dashboard'),
      ),
      body: const Center(
        child: Text('Developer Home - Coming Soon'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Listings'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
