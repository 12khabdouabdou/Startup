import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class AvailableJobsScreen extends StatefulWidget {
  const AvailableJobsScreen({super.key});

  @override
  State<AvailableJobsScreen> createState() => _AvailableJobsScreenState();
}

class _AvailableJobsScreenState extends State<AvailableJobsScreen> {
  List<Map<String, dynamic>> _jobs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    final res = await SupabaseService.client.from('hauls').select('*,waste_posts(*)').eq('status', 'open').order('created_at', ascending: false);
    setState(() { _jobs = List<Map<String, dynamic>>.from(res); _loading = false; });
  }

  Future<void> _acceptJob(String haulId) async {
    try {
      await SupabaseService.client.functions.invoke('accept_haul', body: {'haul_id': haulId});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job accepted!')));
      _loadJobs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Jobs')),
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
                    trailing: ElevatedButton(
                      onPressed: () => _acceptJob(job['id']),
                      child: const Text('Accept'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
