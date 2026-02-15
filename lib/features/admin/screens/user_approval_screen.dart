import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/app_user.dart';
import '../repositories/admin_repository.dart';

class UserApprovalScreen extends ConsumerStatefulWidget {
  final AppUser user;
  const UserApprovalScreen({super.key, required this.user});

  @override
  ConsumerState<UserApprovalScreen> createState() => _UserApprovalScreenState();
}

class _UserApprovalScreenState extends ConsumerState<UserApprovalScreen> {
  bool _isLoading = false;

  Future<void> _handleAction(bool approve) async {
    setState(() => _isLoading = true);
    final repo = ref.read(adminRepositoryProvider);
    try {
      if (approve) {
        await repo.approveUser(widget.user.uid);
      } else {
        await repo.rejectUser(widget.user.uid);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return Scaffold(
      appBar: AppBar(title: Text(u.displayName ?? 'User Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InfoRow(label: 'Role', value: u.role.name.toUpperCase()),
            const SizedBox(height: 8),
            _InfoRow(label: 'Company', value: u.companyName ?? 'N/A'),
            const SizedBox(height: 8),
            _InfoRow(label: 'Phone', value: u.phoneNumber ?? 'N/A'),
            if (u.fleetSize != null) ...[
              const SizedBox(height: 8),
              _InfoRow(label: 'Fleet Size', value: '${u.fleetSize}'),
            ],
            
            const SizedBox(height: 32),
            const Text('Business License / Insurance', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (u.licenseUrl != null)
              Image.network(
                u.licenseUrl!,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                },
                errorBuilder: (context, error, stackTrace) =>
                    Container(height: 200, color: Colors.grey[200], child: const Center(child: Text('Error loading image'))),
              )
            else
              Container(height: 200, color: Colors.grey[200], child: const Center(child: Text('No Document Uploaded'))),

            const SizedBox(height: 48),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => _handleAction(false),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _handleAction(true),
                    child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator()) 
                        : const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value),
      ],
    );
  }
}
