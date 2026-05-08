import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;
    final res = await SupabaseService.client.from('profiles').select('*').eq('id', user.id).single();
    _nameCtrl.text = res['full_name'] ?? '';
    _phoneCtrl.text = res['phone'] ?? '';
    _companyCtrl.text = res['company_name'] ?? '';
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final user = SupabaseService.currentUser;
    await SupabaseService.client.from('profiles').update({
      'full_name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'company_name': _companyCtrl.text.trim(),
    }).eq('id', user!.id);
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(radius: 48, child: Icon(Icons.person, size: 48)),
                  const SizedBox(height: 24),
                  TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
                  const SizedBox(height: 12),
                  TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
                  const SizedBox(height: 12),
                  TextField(controller: _companyCtrl, decoration: const InputDecoration(labelText: 'Company Name')),
                  const SizedBox(height: 24),
                  ElevatedButton(onPressed: _saving ? null : _save, child: _saving ? const CircularProgressIndicator() : const Text('Save')),
                ],
              ),
            ),
    );
  }
}
