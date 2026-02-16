import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/listing_model.dart';
// content of ProfileProvider import removed as it wasn't used in the snippet directly, but might be needed for user info?
// Actually the previous file imported it but used it in Provider? No, wait.
// Let's keep it simple.

class ListingRepository {
  final SupabaseClient _client;

  ListingRepository(this._client);
  
  // Create
  Future<void> createListing(Listing listing) async {
    final data = listing.toMap();
    // Remove nulls or empty strings if Supabase complains, but valid map is usually fine.
    // Ensure createdAt is string.
    data['createdAt'] = DateTime.now().toIso8601String();
    
    // For location, we need to handle GeoPoint replacement.
    // Listing.toMap needs to be updated to return lat/long or PostGIS geometry.
    // We will assume the model update handles this.
    
    await _client.from('listings').insert(data);
  }

  // Read: Stream of active listings
  Stream<List<Listing>> fetchActiveListings() {
    return _client
        .from('listings')
        .stream(primaryKey: ['id'])
        .eq('status', 'active')
        .order('createdAt', ascending: false)
        .map((data) {
            return data.map((json) => Listing.fromMap(json, json['id'] as String)).toList();
        });
  }

  // Update
  Future<void> updateListing(String id, Map<String, dynamic> data) async {
    await _client.from('listings').update(data).eq('id', id);
  }

  // Delete (Archive)
  Future<void> archiveListing(String id) async {
    await updateListing(id, {'status': 'archived'});
  }
}

final listingRepositoryProvider = Provider<ListingRepository>((ref) {
  return ListingRepository(Supabase.instance.client);
});

final activeListingsProvider = StreamProvider.autoDispose<List<Listing>>((ref) {
  final repo = ref.watch(listingRepositoryProvider);
  return repo.fetchActiveListings();
});
