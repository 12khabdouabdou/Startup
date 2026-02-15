import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../../core/services/notification_service.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  bool _newListings = true;
  bool _jobUpdates = true;
  bool _messages = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null) return;

    final settings = await ref.read(notificationServiceProvider).getSettings(uid);
    if (mounted) {
      setState(() {
        _newListings = settings['newListings'] ?? true;
        _jobUpdates = settings['jobUpdates'] ?? true;
        _messages = settings['messages'] ?? true;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null) return;

    await ref.read(notificationServiceProvider).updateSettings(uid, {
      'newListings': _newListings,
      'jobUpdates': _jobUpdates,
      'messages': _messages,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Choose which notifications you want to receive.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),

                SwitchListTile(
                  title: const Text('New Listings Nearby'),
                  subtitle: const Text('Get alerted when new material is posted in your area'),
                  secondary: const Icon(Icons.location_on),
                  value: _newListings,
                  onChanged: (v) {
                    setState(() => _newListings = v);
                    _saveSettings();
                  },
                ),
                const Divider(),

                SwitchListTile(
                  title: const Text('Job Status Updates'),
                  subtitle: const Text('Pickup arrivals, loading complete, delivery updates'),
                  secondary: const Icon(Icons.local_shipping),
                  value: _jobUpdates,
                  onChanged: (v) {
                    setState(() => _jobUpdates = v);
                    _saveSettings();
                  },
                ),
                const Divider(),

                SwitchListTile(
                  title: const Text('Messages'),
                  subtitle: const Text('Direct messages from other users'),
                  secondary: const Icon(Icons.chat),
                  value: _messages,
                  onChanged: (v) {
                    setState(() => _messages = v);
                    _saveSettings();
                  },
                ),
              ],
            ),
    );
  }
}
