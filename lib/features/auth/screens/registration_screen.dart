import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/app_user.dart';
import '../../profile/repositories/profile_repository.dart';
import '../repositories/auth_repository.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  final UserRole? role;

  const RegistrationScreen({super.key, required this.role});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _fleetSizeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _fleetSizeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.role == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: No role selected')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) throw Exception('No authenticated user found');

      final appUser = AppUser(
        uid: user.uid,
        phoneNumber: user.phoneNumber,
        displayName: _nameController.text.trim(),
        companyName: _companyController.text.trim(),
        role: widget.role!,
        status: UserStatus.pending,
        createdAt: DateTime.now(),
        fleetSize: widget.role == UserRole.hauler 
            ? int.tryParse(_fleetSizeController.text.trim()) 
            : null,
      );

      await ref.read(profileRepositoryProvider).createUser(appUser);

      if (mounted) {
        // Router will also pick this up, but manual push is safe
        context.go('/auth/verify-docs');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleName = widget.role?.name.toUpperCase() ?? 'USER';
    final isHauler = widget.role == UserRole.hauler;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Completing profile as $roleName',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _companyController,
                  decoration: const InputDecoration(
                    labelText: 'Company Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                
                if (isHauler) ...[
                  TextFormField(
                    controller: _fleetSizeController,
                    decoration: const InputDecoration(
                      labelText: 'Fleet Size (Trucks)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.local_shipping),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator())
                      : const Text('Create Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
