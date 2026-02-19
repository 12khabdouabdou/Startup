import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/logger.dart';

class LocationService {
  Future<bool> requestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      log.w('[LOCATION] Service is disabled');
      return false; // Could open settings: await Geolocator.openLocationSettings();
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
      return false; // Could open settings: await Geolocator.openAppSettings();
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

  Stream<Position> getPositionStream() {
    log.i('[LOCATION] Starting position stream');
    // Assuming permission checked or check here
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  double distanceBetween(Position a, Position b) {
    final distance = Geolocator.distanceBetween(
      a.latitude, a.longitude, b.latitude, b.longitude,
    );
    // log.d('[LOCATION] Distance: $distance meters');
    return distance;
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});
