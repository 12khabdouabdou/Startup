import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_model.dart';
import '../../auth/repositories/auth_repository.dart';

class ChatRepository {
  final SupabaseClient _client;
  ChatRepository(this._client);

  /// Get or create a chat between two users (optionally for a listing)
  Future<String> getOrCreateChat({
    required String currentUid,
    required String otherUid,
    String? listingId,
  }) async {
    // 1. Check for existing chat
    // We check if participant_ids contains both UIDs
    final response = await _client
        .from('chats')
        .select()
        .contains('participant_ids', [currentUid, otherUid])
        .maybeSingle();

    if (response != null) {
      return response['id'] as String;
    }

    // 2. Create new chat
    final newChat = {
      'participant_ids': [currentUid, otherUid],
      'listing_id': listingId,
      'last_message': null,
      'last_message_at': DateTime.now().toIso8601String(),
    };

    final insertResponse = await _client
        .from('chats')
        .insert(newChat)
        .select()
        .single();
    
    return insertResponse['id'] as String;
  }

  /// Stream all chats for a user
  Stream<List<Chat>> watchUserChats(String uid) {
    return _client
        .from('chats')
        .stream(primaryKey: ['id'])
        // Filter where array contains user id. 
        // Note: Realtime filters on arrays can be tricky. 
        // Supabase stream supports simple equality usually. 'cs' (contains) might not be fully supported in stream filter string??
        // Supabase Flutter SDK .stream() supports specific filters.
        // Actually, for stream, we grab all and filter? No, too heavy.
        // Let's rely on RLS! User can only see their own chats.
        // So we just sort.
        .order('last_message_at', ascending: false)
        .map((data) => data.map((json) => Chat.fromMap(json, json['id'] as String)).toList());
  }

  /// Stream single chat by ID
  Stream<Chat?> watchChat(String chatId) {
    return _client
        .from('chats')
        .stream(primaryKey: ['id'])
        .eq('id', chatId)
        .map((data) {
          if (data.isEmpty) return null;
          return Chat.fromMap(data.first, data.first['id'] as String);
        });
  }

  /// Stream messages for a chat
  Stream<List<ChatMessage>> watchMessages(String chatId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: true)
        .map((data) => data.map((json) => ChatMessage.fromMap(json, json['id'] as String)).toList());
  }

  /// Send a message
  Future<void> sendMessage({
    required String chatId,
    required String senderUid,
    required String text,
  }) async {
    final now = DateTime.now().toIso8601String();
    
    // Insert message
    await _client.from('messages').insert({
      'chat_id': chatId,
      'sender_uid': senderUid,
      'content': text,
      'created_at': now,
      'is_read': false,
    });

    // Update chat last message
    await _client.from('chats').update({
      'last_message': text,
      'last_message_at': now,
    }).eq('id', chatId);
  }
}

// ─── Providers ───────────────────────────────────────

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(Supabase.instance.client);
});

final userChatsProvider = StreamProvider.autoDispose<List<Chat>>((ref) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return const Stream.empty();
  return ref.watch(chatRepositoryProvider).watchUserChats(user.id);
});
