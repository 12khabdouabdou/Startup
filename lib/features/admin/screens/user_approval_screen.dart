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
  final forestGreen = const Color(0xFF2E7D32);

  Future<void> _handleAction(bool approve) async {
    setState(() => _isLoading = true);
    final repo = ref.read(adminRepositoryProvider);
    try {
      if (approve) {
        await repo.approveUser(widget.user.id);
      } else {
        await repo.rejectUser(widget.user.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(approve ? '✅ User Approved' : '❌ User Rejected')),
        );
        context.pop();
      }
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
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        title: const Text('Review Verification'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Summary Card
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[100]!),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: forestGreen.withOpacity(0.1),
                    child: Icon(
                      u.role == UserRole.hauler ? Icons.local_shipping_outlined : Icons.business_outlined,
                      color: forestGreen,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(u.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: forestGreen.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                    child: Text(u.role.name.toUpperCase(), style: TextStyle(color: forestGreen, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 20),
                  _DetailItem(label: 'ORGANIZATION', value: u.companyName ?? 'N/A'),
                  _DetailItem(label: 'CONTACT LINE', value: u.phone ?? 'Not provided'),
                  if (u.fleetSize != null) _DetailItem(label: 'FLEET CAPACITY', value: '${u.fleetSize} Heavy Units'),
                ],
              ),
            ),

            // Document Viewer
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text('VERIFICATION DOCUMENTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
            ),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[100]!),
              ),
              clipBehavior: Clip.antiAlias,
              child: u.licenseUrl != null
                  ? Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          color: Colors.grey[50],
                          child: Row(
                            children: [
                              const Icon(Icons.description_outlined, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              const Expanded(child: Text('Business_License.png', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))),
                              Icon(Icons.open_in_new_rounded, size: 16, color: Colors.grey[400]),
                            ],
                          ),
                        ),
                        Image.network(
                          u.licenseUrl!,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              Container(height: 200, color: Colors.grey[50], child: const Center(child: Text('Error loading image'))),
                        ),
                      ],
                    )
                  : Container(
                      height: 200,
                      color: Colors.grey[50],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange[300], size: 32),
                          const SizedBox(height: 12),
                          const Text('No Document Uploaded', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        ],
                      ),
                    ),
            ),

            const SizedBox(height: 48),

            // Footer Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => _handleAction(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[700],
                        side: BorderSide(color: Colors.red[100]!),
                        height: 56,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('REJECT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _handleAction(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: forestGreen,
                        foregroundColor: Colors.white,
                        height: 56,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isLoading 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                          : const Text('APPROVE USER', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  const _DetailItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 0.5)),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}
