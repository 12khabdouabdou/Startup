import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final res = await SupabaseService.client.from('platform_audit_log').select('*').order('created_at', ascending: false);
    setState(() { _logs = List<Map<String, dynamic>>.from(res); _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audit Log')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                return ListTile(
                  title: Text('${log['action_type']}'),
                  subtitle: Text('Target: ${log['target_user_id'] ?? 'N/A'} | ${log['created_at']}'),
                );
              },
            ),
    );
  }
}
