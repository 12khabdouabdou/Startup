// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_model.dart';
import '../../auth/repositories/auth_repository.dart';

class ChatRepository {
  // final FirebaseFirestore _firestore;
  ChatRepository();

  /// Get or create a chat between two users (optionally for a listing)
  Future<String> getOrCreateChat({
    required String currentUid,
    required String otherUid,
    String? listingId,
  }) async {
    // TODO: Implement Supabase Chat Logic
    return 'mock-chat-id';
  }

  /// Stream all chats for a user
  Stream<List<Chat>> watchUserChats(String uid) {
    // TODO: Implement Supabase Chat Stream
    return Stream.value([]);
  }

  /// Stream messages for a chat
  Stream<List<ChatMessage>> watchMessages(String chatId) {
    // TODO: Implement Supabase Message Stream
    return Stream.value([]);
  }

  /// Send a message
  Future<void> sendMessage({
    required String chatId,
    required String senderUid,
    required String text,
  }) async {
    // TODO: Implement Supabase Send Message
  }
}

// ─── Providers ───────────────────────────────────────

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

final userChatsProvider = StreamProvider.autoDispose<List<Chat>>((ref) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return const Stream.empty();
  return ref.watch(chatRepositoryProvider).watchUserChats(user.id);
});
