import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../repositories/chat_repository.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../profile/providers/profile_provider.dart';
import '../models/chat_model.dart';
// Note: Chat model import was missing in previous file view? No, it wasn't.
// Wait, Step 1655 didn't show chat_model import. But 'chat.participantIds' suggests it knows Chat type?
// Ah, 'final chatsAsync = ref.watch(userChatsProvider);' implies type inference.
// But I should import it explicit if I use it in Tile.

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(userChatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: chatsAsync.when(
        data: (chats) {
          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No conversations yet', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Start by contacting a listing poster!', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              return _ChatListTile(chat: chats[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _ChatListTile extends ConsumerWidget {
  final Chat chat;
  const _ChatListTile({required this.chat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = ref.watch(authRepositoryProvider).currentUser?.id ?? '';
    final otherUid = chat.participantIds.firstWhere(
      (uid) => uid != currentUid,
      orElse: () => '',
    );

    final otherProfileAsync = otherUid.isNotEmpty
        ? ref.watch(userProfileProvider(otherUid))
        : const AsyncValue.data(null);
    
    final displayName = otherProfileAsync.value?.fullName ?? 'User ${otherUid.isEmpty ? 'Unknown' : otherUid.substring(0, min(6, otherUid.length))}';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    final timeLabel = chat.lastMessageAt != null
        ? DateFormat.MMMd().add_jm().format(chat.lastMessageAt!)
        : '';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green.withValues(alpha: 0.15),
        child: Text(
          initial,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
        ),
      ),
      title: Text(
        displayName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        chat.lastMessage ?? 'No messages yet',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(timeLabel, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      onTap: () => context.push('/chat/${chat.id}'),
    );
  }
  
  int min(int a, int b) => a < b ? a : b;
}
