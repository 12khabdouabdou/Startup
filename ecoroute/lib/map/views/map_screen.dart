import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';

class MapScreen extends StatefulWidget {
  final bool isPickerMode;
  final Function(LatLng location)? onLocationSelected;

  const MapScreen({
    super.key,
    this.isPickerMode = false,
    this.onLocationSelected,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    // TODO: Implement actual geolocation
    // For now, use a default location (London)
    final location = LatLng(51.5074, -0.1278);
    _mapController.move(location, 13);
    if (widget.isPickerMode) {
      setState(() => _selectedLocation = location);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _isDarkMode = isDark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
          if (widget.isPickerMode)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _confirmSelection,
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              center: LatLng(51.5074, -0.1278),
              zoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: _isDarkMode
                    ? 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}.png'
                    : 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ecoroute.app',
              ),
              if (widget.isPickerMode && _selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 60,
                      height: 60,
                      point: _selectedLocation!,
                      builder: (ctx) => const Icon(
                        Icons.location_on,
                        size: 60,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              // Add listing markers here when not in picker mode
            ],
          ),
          if (widget.isPickerMode)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _selectedLocation != null
                        ? 'Selected: ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}'
                        : 'Drag map to select location',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmSelection() {
    if (_selectedLocation != null && widget.onLocationSelected != null) {
      widget.onLocationSelected!(_selectedLocation!);
      context.pop(_selectedLocation);
    }
  }
}
