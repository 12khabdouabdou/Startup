import 'package:flutter/material.dart';

class HaulerHome extends StatelessWidget {
  const HaulerHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hauler Dashboard'),
      ),
      body: const Center(
        child: Text('Hauler Home - Coming Soon'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Fleet'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Job Board'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
