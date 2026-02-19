import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/geo_point.dart';
import '../repositories/alert_repository.dart';
import '../../listings/models/listing_model.dart';
import '../../auth/repositories/auth_repository.dart';

class CreateAlertDialog extends ConsumerStatefulWidget {
  final FillMaterial? initialMaterial;

  const CreateAlertDialog({super.key, this.initialMaterial});

  @override
  ConsumerState<CreateAlertDialog> createState() => _CreateAlertDialogState();
}

class _CreateAlertDialogState extends ConsumerState<CreateAlertDialog> {
  FillMaterial? _material;
  double _radiusKm = 20.0;
  bool _isLoading = false;
  bool _useCurrentLocation = true;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _material = widget.initialMaterial;
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      // Check permissions (assuming app handles this globally, but simple check here)
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition();
        if (mounted) setState(() => _currentPosition = pos);
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _createAlert() async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location required for alerts')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final materialStr = _material?.name ?? 'Any'; // Map 'Any' in DB or handle custom
      // NOTE: Our DB Trigger handles 'Any' or specific match.
      // If _material is null, we pass 'Any'.
      
      await ref.read(alertRepositoryProvider).createAlert(
        userId: user.id,
        material: _material != null ? Utils.materialName(_material!) : 'Any',
        location: GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude),
        radiusMeters: (_radiusKm * 1000).toInt(),
      );

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alert Created! We will notify you.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Get Notified'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Material Interest:'),
            const SizedBox(height: 8),
            DropdownButton<FillMaterial?>(
              value: _material,
              isExpanded: true,
              hint: const Text('Any Material'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Any Material')),
                ...FillMaterial.values.map((m) => DropdownMenuItem(
                  value: m,
                  child: Text(Utils.materialName(m)),
                )),
              ],
              onChanged: (v) => setState(() => _material = v),
            ),
            const SizedBox(height: 16),
            
            const Text('Within Radius:'),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _radiusKm,
                    min: 5,
                    max: 100,
                    divisions: 19,
                    label: '${_radiusKm.toInt()} km',
                    onChanged: (v) => setState(() => _radiusKm = v),
                  ),
                ),
                Text('${_radiusKm.toInt()} km'),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: _currentPosition != null ? Colors.green : Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _currentPosition != null 
                        ? 'Using Current Location' 
                        : 'Fetching location...',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isLoading || _currentPosition == null ? null : _createAlert,
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create Alert'),
        ),
      ],
    );
  }
}

class Utils {
  static String materialName(FillMaterial m) {
    return m.name[0].toUpperCase() + m.name.substring(1);
  }
}
