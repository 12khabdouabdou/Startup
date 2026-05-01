import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waste_logistics/models/recycler.dart';
import 'package:waste_logistics/models/user.dart';

class RecyclerService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Recycler> createRecycler(Recycler recycler) async {
    final response = await _supabase.from('recyclers').insert(recycler.toJson()).select();
    return Recycler.fromJson(response.first);
  }

  Future<Recycler?> getRecycler(String recyclerId) async {
    final response = await _supabase
        .from('recyclers')
        .select()
        .eq('id', recyclerId)
        .maybeSingle();

    if (response != null) {
      return Recycler.fromJson(response);
    }
    return null;
  }

  Future<Recycler?> getRecyclerByUserId(String userId) async {
    final response = await _supabase
        .from('recyclers')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response != null) {
      return Recycler.fromJson(response);
    }
    return null;
  }

  Future<List<Recycler>> getNearbyRecyclers(
    double lat,
    double lng,
    double radiusKm,
    WasteType? wasteType,
  ) async {
    var query = _supabase
        .from('recyclers')
        .select()
        .eq('is_active', true);

    if (wasteType != null) {
      query = query.contains('accepted_waste_types', [wasteType.name]);
    }

    final response = await query;

    final nearbyRecyclers = <Recycler>[];
    for (final data in response) {
      final recycler = Recycler.fromJson(data);
      final distance = _calculateDistance(lat, lng, recycler.lat, recycler.lng);
      if (distance <= radiusKm) {
        nearbyRecyclers.add(recycler);
      }
    }

    nearbyRecyclers.sort((a, b) {
      final distA = _calculateDistance(lat, lng, a.lat, a.lng);
      final distB = _calculateDistance(lat, lng, b.lat, b.lng);
      return distA.compareTo(distB);
    });

    return nearbyRecyclers;
  }

  Future<List<Recycler>> getAllRecyclers() async {
    final response = await _supabase
        .from('recyclers')
        .select()
        .eq('is_active', true);

    return response.map((data) => Recycler.fromJson(data)).toList();
  }

  Future<void> updateRecycler(Recycler recycler) async {
    await _supabase.from('recyclers').update(recycler.toJson()).eq('id', recycler.id);
  }

  Future<void> updateRecyclerCapacity(
    String recyclerId,
    double newLoad,
  ) async {
    await _supabase.from('recyclers').update({
      'current_load': newLoad,
    }).eq('id', recyclerId);
  }

  Future<void> updateRecyclerRating(
    String recyclerId,
    double newRating,
    int totalReviews,
  ) async {
    await _supabase.from('recyclers').update({
      'rating': newRating,
      'total_reviews': totalReviews,
    }).eq('id', recyclerId);
  }

  Stream<Recycler?> watchRecycler(String recyclerId) {
    return _supabase
        .from('recyclers')
        .stream(primaryKey: ['id'])
        .eq('id', recyclerId)
        .map((data) => data.isNotEmpty ? Recycler.fromJson(data.first) : null);
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
