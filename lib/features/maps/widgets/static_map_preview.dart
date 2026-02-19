import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/models/geo_point.dart';

class StaticMapPreview extends StatelessWidget {
  final GeoPoint center;
  final double height;
  final double zoom;

  const StaticMapPreview({
    super.key,
    required this.center,
    this.height = 200,
    this.zoom = 15,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(center.latitude, center.longitude),
            initialZoom: zoom,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.fillexchange.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(center.latitude, center.longitude),
                  child: const Icon(Icons.location_on, color: Colors.blue, size: 40),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
