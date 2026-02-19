import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';

/// Shown to users whose account has been rejected or suspended by an admin.
class RejectedScreen extends ConsumerWidget {
  final bool isSuspended;

  const RejectedScreen({super.key, this.isSuspended = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = isSuspended ? 'Account Suspended' : 'Account Not Approved';
    final message = isSuspended
        ? 'Your account has been suspended. Please contact support if you believe this is an error.'
        : 'Your account registration was not approved. This may be due to incomplete or invalid documentation.\n\nIf you believe this is a mistake, please contact support.';
    final icon = isSuspended ? Icons.block : Icons.cancel_outlined;
    final color = isSuspended ? Colors.orange : Colors.red;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 80, color: color),
              const SizedBox(height: 24),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              OutlinedButton.icon(
                onPressed: () => ref.read(authRepositoryProvider).signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
