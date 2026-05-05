import '../../core/network/supabase_client.dart';

class ChatRepository {
  final SupabaseClientInstance _supabase;

  ChatRepository() : _supabase = SupabaseClientInstance();

  Future<List<Map<String, dynamic>>> getConversations(String userId) async {
    try {
      // TODO: Implement Supabase Realtime subscription
      return [];
    } catch (e) {
      throw Exception('Failed to fetch conversations: $e');
    }
  }

  Future<void> sendMessage(String bookingId, String content, String senderId) async {
    try {
      // TODO: Implement
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getMessages(String bookingId) async {
    try {
      // TODO: Implement
      return [];
    } catch (e) {
      throw Exception('Failed to fetch messages: $e');
    }
  }
}
