import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/repositories/auth_repository.dart';
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
    // data['created_at'] is already set by toMap. 
    // We should NOT set 'createdAt' (camelCase) as it doesn't exist in DB.
    
    // For location, we need to handle GeoPoint replacement.
    // Listing.toMap needs to be updated to return lat/long or PostGIS geometry.
    // We will assume the model update handles this.
    
    await _client.from('listings').insert(data).select().single();
    // Could capture ID here? The method returns void though.
  }

  // Read: Stream of active listings
  Stream<List<Listing>> fetchActiveListings() {
    return _client
        .from('listings_view')
        .stream(primaryKey: ['id'])
        .eq('status', ListingStatus.active.name) // Using enum name
        // Fix: Use snake_case created_at
        .order('created_at', ascending: false)
        .map((data) {
            return data.map((json) => Listing.fromMap(json, json['id'] as String)).toList();
        });
  }

  // Read: Stream of user's own listings (Host view)
  Stream<List<Listing>> fetchUserListings(String hostUid) {
    return _client
        .from('listings_view')
        .stream(primaryKey: ['id'])
        .eq('owner_id', hostUid)
        .order('created_at', ascending: false)
        .map((data) {
          return data
              .map((json) => Listing.fromMap(json, json['id'] as String))
              .toList();
        });
  }

  // Update
  Future<void> updateListing(String id, Map<String, dynamic> data) async {
    await _client.from('listings').update(data).eq('id', id);
  }

  // Delete (Archive)
  Future<void> archiveListing(String id) async {
    await updateListing(id, {'status': ListingStatus.archived.name}); // Use enum name
  }

  // Read: Single listing
  Future<Listing?> fetchListing(String id) async {
    try {
      final data = await _client
          .from('listings_view')
          .select()
          .eq('id', id)
          .maybeSingle();
      
      if (data == null) return null;
      return Listing.fromMap(data, id);
    } catch (e) {
      return null;
    }
  }
}

final listingRepositoryProvider = Provider<ListingRepository>((ref) {
  return ListingRepository(Supabase.instance.client);
});

final activeListingsProvider = StreamProvider.autoDispose<List<Listing>>((ref) {
  final repo = ref.watch(listingRepositoryProvider);
  return repo.fetchActiveListings();
});

final myListingsProvider = StreamProvider.autoDispose<List<Listing>>((ref) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return const Stream.empty();
  return ref.watch(listingRepositoryProvider).fetchUserListings(user.id);
});

final listingByIdProvider = FutureProvider.autoDispose.family<Listing?, String>((ref, id) async {
  return ref.watch(listingRepositoryProvider).fetchListing(id);
});
