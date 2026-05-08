import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class BrowseWasteScreen extends StatefulWidget {
  const BrowseWasteScreen({super.key});

  @override
  State<BrowseWasteScreen> createState() => _BrowseWasteScreenState();
}

class _BrowseWasteScreenState extends State<BrowseWasteScreen> {
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    final res = await SupabaseService.client.from('waste_posts').select('*').eq('status', 'posted').order('created_at', ascending: false);
    setState(() { _posts = List<Map<String, dynamic>>.from(res); _loading = false; });
  }

  Future<void> _selectWaste(String postId, double price) async {
    try {
      await SupabaseService.client.functions.invoke('match_recycler', body: {'waste_post_id': postId, 'accepted_price': price});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Waste selected!')));
      _loadPosts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Browse Waste')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                final post = _posts[index];
                return Card(
                  child: ListTile(
                    title: Text('${post['waste_type']} - ${post['quantity']} ${post['quantity_unit']}'),
                    subtitle: Text('Price: \$${post['price']}'),
                    trailing: ElevatedButton(
                      onPressed: () => _selectWaste(post['id'], (post['price'] as num).toDouble()),
                      child: const Text('Select'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
