import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class DeveloperPaymentsScreen extends StatefulWidget {
  const DeveloperPaymentsScreen({super.key});

  @override
  State<DeveloperPaymentsScreen> createState() => _DeveloperPaymentsScreenState();
}

class _DeveloperPaymentsScreenState extends State<DeveloperPaymentsScreen> {
  List<Map<String, dynamic>> _payments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;
    final res = await SupabaseService.client.from('payments').select('*,hauls(*)').order('created_at', ascending: false);
    setState(() { _payments = List<Map<String, dynamic>>.from(res); _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment History')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _payments.length,
              itemBuilder: (context, index) {
                final p = _payments[index];
                return ListTile(
                  title: Text('Payment #${p['id'].toString().substring(0, 8)}'),
                  subtitle: Text('Amount: \$${p['amount']} | Developer Share: \$${p['developer_share']}'),
                  trailing: Chip(label: Text(p['status'])),
                );
              },
            ),
    );
  }
}
