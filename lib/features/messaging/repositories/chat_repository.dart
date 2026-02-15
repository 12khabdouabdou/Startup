import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_model.dart';
import '../../auth/repositories/auth_repository.dart';

class ChatRepository {
  final FirebaseFirestore _firestore;
  ChatRepository(this._firestore);

  /// Get or create a chat between two users (optionally for a listing)
  Future<String> getOrCreateChat({
    required String currentUid,
    required String otherUid,
    String? listingId,
  }) async {
    // Check if chat already exists between these two users
    final existing = await _firestore
        .collection('chats')
        .where('participantUids', arrayContains: currentUid)
        .get();

    for (var doc in existing.docs) {
      final participants = List<String>.from(doc.data()['participantUids'] ?? []);
      if (participants.contains(otherUid)) {
        // If listing-specific, check listing too
        if (listingId != null) {
          if (doc.data()['listingId'] == listingId) return doc.id;
        } else {
          return doc.id;
        }
      }
    }

    // Create new chat
    final ref = await _firestore.collection('chats').add({
      'participantUids': [currentUid, otherUid],
      'listingId': listingId,
      'lastMessage': null,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Stream all chats for a user
  Stream<List<Chat>> watchUserChats(String uid) {
    return _firestore
        .collection('chats')
        .where('participantUids', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Chat.fromMap(d.data(), d.id)).toList());
  }

  /// Stream messages for a chat
  Stream<List<ChatMessage>> watchMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ChatMessage.fromMap(d.data(), d.id)).toList());
  }

  /// Send a message
  Future<void> sendMessage({
    required String chatId,
    required String senderUid,
    required String text,
  }) async {
    final batch = _firestore.batch();

    // Add message to subcollection
    final msgRef = _firestore.collection('chats').doc(chatId).collection('messages').doc();
    batch.set(msgRef, {
      'chatId': chatId,
      'senderUid': senderUid,
      'text': text,
      'sentAt': FieldValue.serverTimestamp(),
    });

    // Update chat's last message
    final chatRef = _firestore.collection('chats').doc(chatId);
    batch.update(chatRef, {
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}

// ─── Providers ───────────────────────────────────────

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(FirebaseFirestore.instance);
});

final userChatsProvider = StreamProvider.autoDispose<List<Chat>>((ref) {
  final uid = ref.watch(authRepositoryProvider).currentUser?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(chatRepositoryProvider).watchUserChats(uid);
});
