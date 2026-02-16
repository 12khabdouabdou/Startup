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
      chatId: data['chatId'] as String? ?? '',
      senderUid: data['senderUid'] as String? ?? '',
      text: data['text'] as String? ?? '',
      sentAt: (data['sentAt'] is String)
          ? DateTime.parse(data['sentAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'chatId': chatId,
    'senderUid': senderUid,
    'text': text,
    'sentAt': sentAt.toIso8601String(),
  };
}

/// A chat thread between two users, optionally linked to a listing
class Chat {
  final String id;
  final List<String> participantUids;
  final String? listingId;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  const Chat({
    required this.id,
    required this.participantUids,
    this.listingId,
    this.lastMessage,
    this.lastMessageAt,
  });

  factory Chat.fromMap(Map<String, dynamic> data, String id) {
    return Chat(
      id: id,
      participantUids: List<String>.from(data['participantUids'] ?? []),
      listingId: data['listingId'] as String?,
      lastMessage: data['lastMessage'] as String?,
      lastMessageAt: (data['lastMessageAt'] is String)
          ? DateTime.parse(data['lastMessageAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'participantUids': participantUids,
    'listingId': listingId,
    'lastMessage': lastMessage,
    'lastMessageAt': lastMessageAt,
  };
}
