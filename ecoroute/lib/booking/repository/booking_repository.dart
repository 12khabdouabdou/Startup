import '../../core/network/supabase_client.dart';
import '../models/booking_model.dart';

class BookingRepository {
  final SupabaseClientInstance _supabase = SupabaseClientInstance();

  Future<List<BookingModel>> getBookingsForUser(String userId, String role) async {
    final field = switch (role) {
      'developer' => 'developer_id',
      'hauler' => 'hauler_id',
      'recycler' => 'recycler_id',
      _ => 'developer_id',
    };

    final response = await _supabase.client
        .from('bookings')
        .select()
        .eq(field, userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => BookingModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<BookingModel?> getBookingById(String id) async {
    final response = await _supabase.client
        .from('bookings')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return BookingModel.fromJson(response as Map<String, dynamic>);
  }

  Future<BookingModel> createBooking(Map<String, dynamic> data) async {
    final response = await _supabase.client
        .from('bookings')
        .insert(data)
        .select()
        .single();

    return BookingModel.fromJson(response as Map<String, dynamic>);
  }

  Future<void> updateBookingStatus(String id, BookingStatus status) async {
    await _supabase.client
        .from('bookings')
        .update({'status': status.name, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id);

    await _supabase.client.from('booking_status_history').insert({
      'booking_id': id,
      'status': status.name,
      'changed_at': DateTime.now().toIso8601String(),
    });
  }
}
