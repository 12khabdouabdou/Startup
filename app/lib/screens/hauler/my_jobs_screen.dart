import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  List<Map<String, dynamic>> _jobs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;
    final res = await SupabaseService.client.from('hauls').select('*,waste_posts(*)').eq('hauler_id', user.id).order('created_at', ascending: false);
    setState(() { _jobs = List<Map<String, dynamic>>.from(res); _loading = false; });
  }

  Future<void> _confirmPickup(String haulId) async {
    try {
      await SupabaseService.client.functions.invoke('confirm_pickup', body: {'haul_id': haulId});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pickup confirmed!')));
      _loadJobs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _confirmDelivery(String haulId) async {
    try {
      await SupabaseService.client.functions.invoke('confirm_delivery', body: {'haul_id': haulId});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delivery confirmed!')));
      _loadJobs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Jobs')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _jobs.length,
              itemBuilder: (context, index) {
                final job = _jobs[index];
                return Card(
                  child: ListTile(
                    title: Text('Haul #${job['id'].toString().substring(0, 8)}'),
                    subtitle: Text('Status: ${job['status']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (job['status'] == 'accepted') ElevatedButton(onPressed: () => _confirmPickup(job['id']), child: const Text('Pickup')),
                        if (job['status'] == 'picked_up') ElevatedButton(onPressed: () => _confirmDelivery(job['id']), child: const Text('Deliver')),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
