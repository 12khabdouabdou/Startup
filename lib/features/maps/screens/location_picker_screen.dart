import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:go_router/go_router.dart';
import '../../../core/models/geo_point.dart';

class LocationResult {
  final GeoPoint point;
  final String address;

  LocationResult({required this.point, required this.address});
}

class LocationPickerScreen extends StatefulWidget {
  final GeoPoint? initialLocation;

  const LocationPickerScreen({super.key, this.initialLocation});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  LatLng _center = const LatLng(48.8566, 2.3522); // Default Paris
  String _address = 'Move map to select location';
  bool _isLoadingAddress = false;
  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _center = LatLng(widget.initialLocation!.latitude, widget.initialLocation!.longitude);
      _getAddress(_center);
      _isInit = false;
    } else {
      _locateUser();
    }
  }

  Future<void> _locateUser() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition();
      final userLoc = LatLng(position.latitude, position.longitude);
      
      if (mounted) {
        setState(() {
          _center = userLoc;
          if (_isInit) {
             _mapController.move(userLoc, 15);
             _getAddress(userLoc);
             _isInit = false;
          } else {
             _mapController.move(userLoc, 15);
          }
        });
      }
    } catch (e) {
      debugPrint('Error locating user: $e');
    }
  }

  Future<void> _getAddress(LatLng pos) async {
    if (_isLoadingAddress) return;
    setState(() => _isLoadingAddress = true);

    try {
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final address = [
          p.street,
          p.subLocality,
          p.locality,
          p.postalCode,
          p.country
        ].where((e) => e != null && e.isNotEmpty).join(', ');
        
        if (mounted) setState(() => _address = address);
      } else {
        if (mounted) setState(() => _address = '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}');
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
      if (mounted) setState(() => _address = 'Unknown Location');
    } finally {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture) {
       _center = camera.center;
       // Debounce address fetch? For now, do it on "Confirm" or separate logic?
       // Doing it on drag end is better.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
               _locateUser();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15,
              onPositionChanged: _onPositionChanged,
              onMapEvent: (evt) {
                 if (evt is MapEventMoveEnd) {
                    _getAddress(evt.camera.center);
                 }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.fillexchange.app', // Update with real package name
              ),
              // Attribution required by OSM
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors',
                    onTap: () {}, // Can launch URL
                  ),
                ],
              ),
            ],
          ),
          
          // Center Pin
          const Center(
            child: Icon(Icons.location_on, size: 48, color: Colors.red),
          ),
          
          // Bottom Sheet with Address & Confirm
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Selected Location', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.BOLD)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.place, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _isLoadingAddress 
                             ? const LinearProgressIndicator() 
                             : Text(_address, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoadingAddress ? null : () {
                        context.pop(LocationResult(
                          point: GeoPoint(_center.latitude, _center.longitude),
                          address: _address,
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Confirm Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
