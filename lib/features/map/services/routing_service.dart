import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RoutingService {
  // Using OSRM Demo Server (Free, usage limits apply)
  // For production, consider Mapbox or self-hosted OSRM.
  static const String _baseUrl = 'https://router.project-osrm.org/route/v1/driving';

  Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    final startCoord = '${start.longitude},${start.latitude}';
    final endCoord = '${end.longitude},${end.latitude}';
    
    final url = Uri.parse('$_baseUrl/$startCoord;$endCoord?overview=full&geometries=geojson');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] != 'Ok') {
          throw Exception('OSRM Error: ${data['code']}');
        }

        final routes = data['routes'] as List;
        if (routes.isEmpty) return [];

        final checkGeometry = routes[0]['geometry'];
        if (checkGeometry == null) return [];

        final coordinates = checkGeometry['coordinates'] as List;
        
        return coordinates.map((coord) {
          final point = coord as List;
          // OSRM returns [lng, lat]
          return LatLng(point[1].toDouble(), point[0].toDouble());
        }).toList();
      } else {
        throw Exception('Failed to load route: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback: If routing fails, return straight line
      return [start, end];
    }
  }
}
