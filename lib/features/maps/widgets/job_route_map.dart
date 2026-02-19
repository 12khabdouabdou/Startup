import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/models/geo_point.dart';

class JobRouteMap extends StatelessWidget {
  final GeoPoint pickup;
  final GeoPoint dropoff;
  final double height;

  const JobRouteMap({
    super.key,
    required this.pickup,
    required this.dropoff,
    this.height = 250,
  });

  @override
  Widget build(BuildContext context) {
    if (pickup.latitude == 0 && pickup.longitude == 0 && dropoff.latitude == 0 && dropoff.longitude == 0) {
      return const SizedBox();
    }

    final pickupLatLng = LatLng(pickup.latitude, pickup.longitude);
    final dropoffLatLng = LatLng(dropoff.latitude, dropoff.longitude);
    
    // Safety check for empty points
    final bool hasPickup = pickup.latitude != 0 || pickup.longitude != 0;
    final bool hasDropoff = dropoff.latitude != 0 || dropoff.longitude != 0;

    if (!hasPickup && !hasDropoff) return const SizedBox();
    
    LatLng center;
    double zoom = 13;
    
    if (hasPickup && hasDropoff) {
      final bounds = LatLngBounds(pickupLatLng, dropoffLatLng);
      center = bounds.center;
      // Simple zoom estimation or use fitCamera in non-static context
      // Since we can't easily auto-fit in initial options without constraints, 
      // we'll center between them. Ideally use MapController to fitBounds after build.
      // For now, center is fine. Users can pan/zoom.
    } else {
      center = hasPickup ? pickupLatLng : dropoffLatLng;
    }

    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
            // Allow interaction to let user explore route
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.fillexchange.app',
            ),
            if (hasPickup && hasDropoff)
              PolylineLayer(
                polylines: <Polyline<Object>>[
                  Polyline(
                    points: [pickupLatLng, dropoffLatLng],
                    strokeWidth: 4.0,
                    color: Colors.blue.withOpacity(0.7),
                    pattern: const StrokePattern.dotted(),
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                if (hasPickup)
                  Marker(
                    point: pickupLatLng,
                    child: const Icon(Icons.location_on, color: Colors.green, size: 40),
                  ),
                if (hasDropoff)
                  Marker(
                    point: dropoffLatLng,
                    child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                  ),
              ],
            ),
             // Attribution
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors', onTap: () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
