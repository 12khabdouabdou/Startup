import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class MySelectionsScreen extends StatefulWidget {
  const MySelectionsScreen({super.key});

  @override
  State<MySelectionsScreen> createState() => _MySelectionsScreenState();
}

class _MySelectionsScreenState extends State<MySelectionsScreen> {
  List<Map<String, dynamic>> _selections = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSelections();
  }

  Future<void> _loadSelections() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;
    final res = await SupabaseService.client.from('waste_selections').select('*,waste_posts(*)').eq('recycler_id', user.id).order('selected_at', ascending: false);
    setState(() { _selections = List<Map<String, dynamic>>.from(res); _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Selections')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _selections.length,
              itemBuilder: (context, index) {
                final sel = _selections[index];
                return ListTile(
                  title: Text('${sel['waste_posts']['waste_type']} - ${sel['waste_posts']['quantity']} ${sel['waste_posts']['quantity_unit']}'),
                  subtitle: Text('Selected at: ${sel['selected_at']}'),
                );
              },
            ),
    );
  }
}
