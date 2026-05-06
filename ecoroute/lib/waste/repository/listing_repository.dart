import '../../core/network/supabase_client.dart';
import '../models/waste_listing_model.dart';

class ListingRepository {
  final SupabaseClientInstance _supabase = SupabaseClientInstance();

  Future<List<WasteListingModel>> getAllListings() async {
    final response = await _supabase.client
        .from('waste_listings')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => WasteListingModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<WasteListingModel>> getListingsByDeveloper(String developerId) async {
    final response = await _supabase.client
        .from('waste_listings')
        .select()
        .eq('developer_id', developerId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => WasteListingModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<WasteListingModel?> getListingById(String id) async {
    final response = await _supabase.client
        .from('waste_listings')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return WasteListingModel.fromJson(response as Map<String, dynamic>);
  }

  Future<WasteListingModel> createListing(Map<String, dynamic> data) async {
    final response = await _supabase.client
        .from('waste_listings')
        .insert(data)
        .select()
        .single();

    return WasteListingModel.fromJson(response as Map<String, dynamic>);
  }

  Future<void> updateListing(String id, Map<String, dynamic> updates) async {
    await _supabase.client
        .from('waste_listings')
        .update(updates)
        .eq('id', id);
  }

  Future<void> deleteListing(String id) async {
    await _supabase.client.from('waste_listings').delete().eq('id', id);
  }
}
