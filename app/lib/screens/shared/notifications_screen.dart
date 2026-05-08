import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;
    final res = await SupabaseService.client
        .from('notifications')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    setState(() {
      _notifications = List<Map<String, dynamic>>.from(res);
      _loading = false;
    });
  }

  Future<void> _markRead(String id) async {
    await SupabaseService.client.from('notifications').update({'read': true}).eq('id', id);
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('No notifications'))
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final n = _notifications[index];
                    return ListTile(
                      leading: Icon(n['read'] ? Icons.check_circle : Icons.circle, color: n['read'] ? Colors.grey : Colors.green),
                      title: Text(n['title']),
                      subtitle: Text(n['body']),
                      onTap: () => _markRead(n['id']),
                    );
                  },
                ),
    );
  }
}
