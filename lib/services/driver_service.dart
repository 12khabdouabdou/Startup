import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waste_logistics/models/driver.dart';
import 'package:waste_logistics/models/order.dart';

class DriverService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Driver> createDriver(Driver driver) async {
    final response = await _supabase.from('drivers').insert(driver.toJson()).select();
    return Driver.fromJson(response.first);
  }

  Future<Driver?> getDriver(String driverId) async {
    final response = await _supabase
        .from('drivers')
        .select()
        .eq('id', driverId)
        .maybeSingle();

    if (response != null) {
      return Driver.fromJson(response);
    }
    return null;
  }

  Future<Driver?> getDriverByUserId(String userId) async {
    final response = await _supabase
        .from('drivers')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response != null) {
      return Driver.fromJson(response);
    }
    return null;
  }

  Future<List<Driver>> getAvailableDrivers() async {
    final response = await _supabase
        .from('drivers')
        .select()
        .eq('is_available', true);

    return response.map((data) => Driver.fromJson(data)).toList();
  }

  Future<List<Driver>> getNearbyDrivers(
    double lat,
    double lng,
    double radiusKm,
  ) async {
    final response = await _supabase
        .from('drivers')
        .select()
        .eq('is_available', true);

    final nearbyDrivers = <Driver>[];
    for (final data in response) {
      final driver = Driver.fromJson(data);
      final distance = _calculateDistance(lat, lng, driver.lat, driver.lng);
      if (distance <= radiusKm) {
        nearbyDrivers.add(driver);
      }
    }

    nearbyDrivers.sort((a, b) {
      final distA = _calculateDistance(lat, lng, a.lat, a.lng);
      final distB = _calculateDistance(lat, lng, b.lat, b.lng);
      return distA.compareTo(distB);
    });

    return nearbyDrivers;
  }

  Future<void> updateDriverAvailability(
    String driverId,
    bool isAvailable,
  ) async {
    await _supabase.from('drivers').update({
      'is_available': isAvailable,
    }).eq('id', driverId);
  }

  Future<void> updateDriverLocation(
    String driverId,
    double lat,
    double lng,
  ) async {
    await _supabase.from('drivers').update({
      'lat': lat,
      'lng': lng,
    }).eq('id', driverId);
  }

  Future<void> assignOrderToDriver(
    String driverId,
    String orderId,
  ) async {
    await _supabase.from('drivers').update({
      'current_order_id': orderId,
      'is_available': false,
    }).eq('id', driverId);
  }

  Future<void> completeOrder(
    String driverId,
    String orderId,
    double earnings,
  ) async {
    final driver = await getDriver(driverId);
    if (driver != null) {
      await _supabase.from('drivers').update({
        'current_order_id': null,
        'is_available': true,
        'total_deliveries': driver.totalDeliveries + 1,
        'total_earnings': driver.totalEarnings + earnings,
      }).eq('id', driverId);
    }
  }

  Future<void> updateDriverRating(
    String driverId,
    double newRating,
  ) async {
    final driver = await getDriver(driverId);
    if (driver != null) {
      await _supabase.from('drivers').update({
        'rating': newRating,
      }).eq('id', driverId);
    }
  }

  Stream<Driver?> watchDriver(String driverId) {
    return _supabase
        .from('drivers')
        .stream(primaryKey: ['id'])
        .eq('id', driverId)
        .map((data) => data.isNotEmpty ? Driver.fromJson(data.first) : null);
  }

  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a = (dLat * dLat) +
        (dLng * dLng) * (lat1 + lat2) / 2;

    return earthRadius * a;
  }

  double _toRadians(double degrees) {
    return degrees * 3.14159265359 / 180;
  }
}
