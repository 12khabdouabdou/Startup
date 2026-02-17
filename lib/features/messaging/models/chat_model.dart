// import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String chatId;
  final String senderUid;
  final String text;
  final DateTime sentAt;

  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderUid,
    required this.text,
    required this.sentAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> data, String id) {
    return ChatMessage(
      id: id,
      chatId: data['chat_id'] as String? ?? '',
      senderUid: data['sender_uid'] as String? ?? '',
      text: data['content'] as String? ?? '', // 'content' in schema
      sentAt: (data['created_at'] is String)
          ? DateTime.parse(data['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'chat_id': chatId,
    'sender_uid': senderUid,
    'content': text,
    'created_at': sentAt.toIso8601String(),
    'is_read': false,
  };
}

/// A chat thread between two users, optionally linked to a listing
class Chat {
  final String id;
  final List<String> participantIds;
  final String? listingId;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  const Chat({
    required this.id,
    required this.participantIds,
    this.listingId,
    this.lastMessage,
    this.lastMessageAt,
  });

  factory Chat.fromMap(Map<String, dynamic> data, String id) {
    // Handle participant_ids (might be list or string array form Supabase)
    // Supabase returns array as List<dynamic>
    final parts = (data['participant_ids'] as List?)?.map((e) => e.toString()).toList() ?? [];

    return Chat(
      id: id,
      participantIds: parts,
      listingId: data['listing_id'] as String?,
      lastMessage: data['last_message'] as String?,
      lastMessageAt: (data['last_message_at'] is String)
          ? DateTime.parse(data['last_message_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'participant_ids': participantIds,
    'listing_id': listingId,
    'last_message': lastMessage,
    'last_message_at': lastMessageAt?.toIso8601String(),
  };
}
