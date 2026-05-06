import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';

class MapScreen extends StatefulWidget {
  final bool isPickerMode;
  final LatLng? initialPosition;
  final void Function(LatLng location)? onLocationSelected;

  const MapScreen({
    super.key,
    this.isPickerMode = false,
    this.initialPosition,
    this.onLocationSelected,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;

  static const _defaultCenter = LatLng(51.5074, -0.1278);

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialPosition;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isPickerMode ? 'Pick Location' : 'Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _centerOnUserLocation,
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
            options: MapOptions(
              initialCenter: _selectedLocation ?? _defaultCenter,
              initialZoom: 13,
              onTap: (tapPosition, point) {
                if (widget.isPickerMode) {
                  setState(() => _selectedLocation = point);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: isDark
                    ? 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png'
                    : 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                userAgentPackageName: 'com.ecoroute.app',
              ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      key: ValueKey(_selectedLocation),
                      width: 60,
                      height: 60,
                      point: _selectedLocation!,
                      child: const Icon(
                        Icons.location_on,
                        size: 60,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
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
                        : 'Tap map to select location',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _centerOnUserLocation() async {
    // TODO: Use geolocator to get real position
    const location = _defaultCenter;
    _mapController.move(location, 13);
    if (widget.isPickerMode) {
      setState(() => _selectedLocation = location);
    }
  }

  void _confirmSelection() {
    if (_selectedLocation != null) {
      widget.onLocationSelected?.call(_selectedLocation!);
      context.pop({
        'lat': _selectedLocation!.latitude,
        'lng': _selectedLocation!.longitude,
      });
    }
  }
}
