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
    const forestGreen = Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: chatsAsync.when(
        data: (chats) {
          if (chats.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                      child: Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey[300]),
                    ),
                    const SizedBox(height: 24),
                    const Text('Inbox is Quiet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Start a conversation with a potential partner to see messages here.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: chats.length,
            separatorBuilder: (_, __) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Divider(height: 1),
            ),
            itemBuilder: (context, index) {
              return _ChatListTile(chat: chats[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: forestGreen)),
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
    const forestGreen = Color(0xFF2E7D32);

    final otherProfileAsync = otherUid.isNotEmpty
        ? ref.watch(userProfileProvider(otherUid))
        : const AsyncValue<AppUser?>.data(null);
    
    final displayName = otherProfileAsync.value?.fullName ?? 'User';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    final timeLabel = chat.lastMessageAt != null
        ? _formatDate(chat.lastMessageAt!)
        : '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: forestGreen.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: const TextStyle(fontWeight: FontWeight.w900, color: forestGreen, fontSize: 18),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              displayName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Text(timeLabel, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          chat.lastMessage ?? 'No messages yet',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
      onTap: () => context.push('/chat/${chat.id}'),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) return DateFormat.jm().format(date);
    if (difference.inDays < 7) return DateFormat('EEEE').format(date);
    return DateFormat.MMMd().format(date);
  }
}
