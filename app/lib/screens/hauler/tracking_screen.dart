import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/supabase_service.dart';

class TrackingScreen extends StatefulWidget {
  final String haulId;
  const TrackingScreen({super.key, required this.haulId});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  LatLng? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  final MapController _mapController = MapController();
  List<LatLng> _route = [];

  @override
  void initState() {
    super.initState();
    _initTracking();
  }

  Future<void> _initTracking() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(distanceFilter: 10),
    ).listen((position) {
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentPosition = latLng;
        _route.add(latLng);
      });
      _mapController.move(latLng, 15);
      _sendPosition(position.latitude, position.longitude);
    });
  }

  Future<void> _sendPosition(double lat, double lng) async {
    try {
      await SupabaseService.client.functions.invoke(
        'track_position',
        body: {'haul_id': widget.haulId, 'lat': lat, 'lng': lng},
      );
    } catch (e) {
      debugPrint('Track error: $e');
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Tracking')),
      body: _currentPosition == null
          ? const Center(child: Text('Acquiring GPS...'))
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentPosition!,
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.cwl.app',
                ),
                if (_route.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _route,
                        color: Colors.blue,
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.local_shipping, color: Colors.green, size: 40),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
