import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;
    final res = await SupabaseService.client.from('waste_posts').select('*').eq('developer_id', user.id).order('created_at', ascending: false);
    setState(() { _posts = List<Map<String, dynamic>>.from(res); _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Posts')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                final post = _posts[index];
                return ListTile(
                  title: Text('${post['waste_type']} - ${post['quantity']} ${post['quantity_unit']}'),
                  subtitle: Text('Status: ${post['status']} | Price: \$${post['price']}'),
                  trailing: Chip(label: Text(post['status'])),
                );
              },
            ),
    );
  }
}
