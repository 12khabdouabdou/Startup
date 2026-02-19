import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/geo_point.dart';

class AlertRepository {
  final SupabaseClient _client;

  AlertRepository(this._client);

  Future<void> createAlert({
    required String userId,
    required String material,
    required GeoPoint location,
    required int radiusMeters,
  }) async {
    await _client.from('listing_alerts').insert({
      'user_id': userId,
      'material': material,
      // Store as PostGIS point
      'location': 'POINT(${location.longitude} ${location.latitude})',
      'radius_meters': radiusMeters,
    });
  }

  Stream<List<Map<String, dynamic>>> fetchMyAlerts(String userId) {
    return _client
        .from('listing_alerts')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  Future<void> deleteAlert(String alertId) async {
    await _client.from('listing_alerts').delete().eq('id', alertId);
  }
}

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  return AlertRepository(Supabase.instance.client);
});
