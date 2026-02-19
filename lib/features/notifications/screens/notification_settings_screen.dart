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
  double _radiusMiles = 25.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = ref.read(userDocProvider).valueOrNull;
    if (user != null) {
      setState(() {
        // We'll simulate loading from the user doc or a preference table
        // For real implementation, these would be columns in public.users
        _radiusMiles = 25.0; // Default
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
     // Implementation would update public.users table with new preferences
     ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences updated ✅')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Notifications')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'ALERTS CONFIGURATION',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1),
                  ),
                ),
                const SizedBox(height: 12),
                _buildToggle(
                  'New Listings Nearby',
                  'Alert me when new fill drops in my area',
                  Icons.location_on_outlined,
                  _newListings,
                  (v) => setState(() => _newListings = v),
                ),
                if (_newListings) ...[
                   Padding(
                     padding: const EdgeInsets.fromLTRB(72, 0, 20, 12),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                             Text('Search Radius', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                             Text('${_radiusMiles.toInt()} miles', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                           ],
                         ),
                         Slider(
                           value: _radiusMiles,
                           min: 5,
                           max: 100,
                           divisions: 19,
                           activeColor: const Color(0xFF2E7D32),
                           onChanged: (v) => setState(() => _radiusMiles = v),
                           onChangeEnd: (_) => _saveSettings(),
                         ),
                       ],
                     ),
                   ),
                ],
                _buildToggle(
                  'Job Status Updates',
                  'Pickups, loading, and delivery status',
                  Icons.local_shipping_outlined,
                  _jobUpdates,
                  (v) => setState(() => _jobUpdates = v),
                ),
                _buildToggle(
                  'Messages',
                  'Direct messages from other users',
                  Icons.chat_bubble_outline,
                  _messages,
                  (v) => setState(() => _messages = v),
                ),
                
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 40, 20, 20),
                  child: Divider(),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PUSH SETTINGS',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () {
                          // Open OS app settings
                        },
                        icon: const Icon(Icons.settings_outlined, size: 18),
                        label: const Text('Advanced System Notification Settings'),
                        style: TextButton.styleFrom(foregroundColor: Colors.blueGrey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildToggle(String title, String subtitle, IconData icon, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      value: value,
      onChanged: (v) {
        onChanged(v);
        _saveSettings();
      },
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      secondary: Icon(icon, color: value ? const Color(0xFF2E7D32) : Colors.grey),
      activeColor: const Color(0xFF2E7D32),
    );
  }
}
