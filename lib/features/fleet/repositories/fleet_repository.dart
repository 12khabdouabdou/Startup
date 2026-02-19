import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/truck_model.dart';
import '../../auth/repositories/auth_repository.dart';

class FleetRepository {
  final SupabaseClient _client;
  FleetRepository(this._client);

  Future<List<Truck>> fetchMyFleet(String userId) async {
    final response = await _client
        .from('fleet')
        .select()
        .eq('owner_uid', userId)
        .order('created_at', ascending: false);
    
    return (response as List).map((e) => Truck.fromMap(e, e['id'] as String)).toList();
  }

  Future<void> addTruck(Truck truck) async {
    await _client.from('fleet').insert(truck.toMap());
  }

  Future<void> updateTruck(Truck truck) async {
    await _client.from('fleet').update(truck.toMap()).eq('id', truck.id);
  }

  Future<void> deleteTruck(String id) async {
    await _client.from('fleet').delete().eq('id', id);
  }

  Future<void> toggleTruckStatus(String id, bool active) async {
    await _client.from('fleet').update({'is_active': active}).eq('id', id);
  }
}

final fleetRepositoryProvider = Provider<FleetRepository>((ref) {
  return FleetRepository(Supabase.instance.client);
});

final myFleetProvider = FutureProvider.autoDispose<List<Truck>>((ref) async {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return [];
  return ref.watch(fleetRepositoryProvider).fetchMyFleet(user.id);
});
