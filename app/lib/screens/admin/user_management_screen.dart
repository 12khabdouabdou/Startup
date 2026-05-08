import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final res = await SupabaseService.client.from('profiles').select('*').order('created_at', ascending: false);
    setState(() { _users = List<Map<String, dynamic>>.from(res); _loading = false; });
  }

  Future<void> _banUser(String userId) async {
    try {
      await SupabaseService.client.functions.invoke('ban_user', body: {'user_id': userId});
      _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final u = _users[index];
                return ListTile(
                  title: Text(u['full_name'] ?? 'Unknown'),
                  subtitle: Text('Role: ${u['role']} | Status: ${u['verification_status']}'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (u['role'] == 'hauler' && u['verification_status'] == 'pending')
                      IconButton(icon: const Icon(Icons.check), onPressed: () async {
                        await SupabaseService.client.functions.invoke('approve_hauler', body: {'user_id': u['id']});
                        _loadUsers();
                      }),
                    if (!u['banned']) IconButton(icon: const Icon(Icons.block), onPressed: () => _banUser(u['id'])),
                  ]),
                );
              },
            ),
    );
  }
}
