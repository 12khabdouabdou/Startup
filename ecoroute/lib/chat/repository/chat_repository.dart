import '../../core/network/supabase_client.dart';

class ChatRepository {
  final SupabaseClientInstance _supabase = SupabaseClientInstance();

  Future<List<Map<String, dynamic>>> getConversations(String userId) async {
    final response = await _supabase.client
        .from('messages')
        .select('booking_id, content, created_at, sender_id')
        .or('sender_id.eq.$userId,receiver_id.eq.$userId')
        .order('created_at', ascending: false);

    final seen = <String>{};
    final conversations = <Map<String, dynamic>>[];

    for (final msg in response as List) {
      final bookingId = msg['booking_id'] as String;
      if (seen.add(bookingId)) {
        conversations.add(msg as Map<String, dynamic>);
      }
    }

    return conversations;
  }

  Future<void> sendMessage(
    String bookingId,
    String content,
    String senderId,
  ) async {
    await _supabase.client.from('messages').insert({
      'booking_id': bookingId,
      'sender_id': senderId,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getMessages(String bookingId) async {
    final response = await _supabase.client
        .from('messages')
        .select()
        .eq('booking_id', bookingId)
        .order('created_at', ascending: true);

    return (response as List).cast<Map<String, dynamic>>();
  }

  Stream<List<Map<String, dynamic>>> watchMessages(String bookingId) {
    return _supabase.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('booking_id', bookingId)
        .order('created_at')
        .map((rows) => rows.toList());
  }
}
