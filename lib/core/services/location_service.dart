import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

class LocationService {
  final SupabaseClient _supabase;

  LocationService(this._supabase);

  Future<bool> requestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      log.w('[LOCATION] Service is disabled');
      return false; 
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      log.i('[LOCATION] Requesting permission');
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        log.w('[LOCATION] Permission denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      log.e('[LOCATION] Permission denied forever');
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) return null;

      log.i('[LOCATION] Getting current position');
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e, stack) {
      log.e('[LOCATION] Error fetching position', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Updates the user's location in the database (Story 5.1)
  /// This enables Geo-Fenced "New Dirt Alerts".
  Future<void> updateUserLocation(String uid) async {
    final position = await getCurrentPosition();
    if (position == null) return;

    try {
      // Use GeoJSON format for PostGIS
      await _supabase.from('users').update({
        'location': {
          'type': 'Point',
          'coordinates': [position.longitude, position.latitude]
        },
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('uid', uid);
      
      log.i('[LOCATION] User location updated in DB: [${position.longitude}, ${position.latitude}]');
    } catch (e) {
      log.e('[LOCATION] Failed to update user location: $e');
    }
  }

  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  double distanceBetween(Position a, Position b) {
    return Geolocator.distanceBetween(
      a.latitude, a.longitude, b.latitude, b.longitude,
    );
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService(Supabase.instance.client);
});
