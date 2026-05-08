import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import 'dart:io';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _typeCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return;
      await SupabaseService.client.from('waste_posts').insert({
        'developer_id': user.id,
        'waste_type': _typeCtrl.text,
        'quantity': double.parse(_quantityCtrl.text),
        'quantity_unit': 'tons',
        'location': 'SRID=4326;POINT(${_lngCtrl.text} ${_latCtrl.text})',
        'price': double.parse(_priceCtrl.text),
        'status': 'posted',
      });
      if (!mounted) return;
      Navigator.pop(context);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Waste Post')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(controller: _typeCtrl, decoration: const InputDecoration(labelText: 'Waste Type (concrete, wood, etc.)')),
            TextField(controller: _quantityCtrl, decoration: const InputDecoration(labelText: 'Quantity (tons)'), keyboardType: TextInputType.number),
            TextField(controller: _latCtrl, decoration: const InputDecoration(labelText: 'Latitude'), keyboardType: TextInputType.number),
            TextField(controller: _lngCtrl, decoration: const InputDecoration(labelText: 'Longitude'), keyboardType: TextInputType.number),
            TextField(controller: _priceCtrl, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _loading ? null : _submit, child: _loading ? const CircularProgressIndicator() : const Text('Post Waste')),
          ],
        ),
      ),
    );
  }
}
