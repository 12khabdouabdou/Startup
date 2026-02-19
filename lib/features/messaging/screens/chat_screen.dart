import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/chat_model.dart';
import '../repositories/chat_repository.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../profile/providers/profile_provider.dart';
import '../../../core/models/app_user.dart';
import 'package:go_router/go_router.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  const ChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;
  final forestGreen = const Color(0xFF2E7D32);

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final uid = ref.read(authRepositoryProvider).currentUser?.id;
    if (uid == null) return;

    _controller.clear();
    setState(() => _isSending = true);

    try {
      await ref.read(chatRepositoryProvider).sendMessage(
        chatId: widget.chatId,
        senderUid: uid,
        text: text,
      );

      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(_messagesProvider(widget.chatId));
    final currentUid = ref.watch(authRepositoryProvider).currentUser?.id ?? '';
    
    // Resolve Peer Name Logic
    final chatAsync = ref.watch(_chatProvider(widget.chatId));
    final chat = chatAsync.value;
    final otherUid = chat?.participantIds.firstWhere((id) => id != currentUid, orElse: () => '') ?? '';
    
    final otherProfileAsync = otherUid.isNotEmpty ? ref.watch(userProfileProvider(otherUid)) : const AsyncValue<AppUser?>.loading();
    final otherName = otherProfileAsync.value?.fullName ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(otherName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            if (otherProfileAsync.isLoading) 
              Text('Syncing...', style: TextStyle(fontSize: 11, color: forestGreen.withOpacity(0.6)))
            else
              Text('Network Partner', style: TextStyle(fontSize: 10, color: Colors.grey[400], fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ],
        ),
        actions: [
          if (chat?.listingId?.isNotEmpty == true)
             Padding(
               padding: const EdgeInsets.only(right: 8),
               child: IconButton(
                 icon: const Icon(Icons.local_shipping_outlined, color: forestGreen),
                 tooltip: 'Create Haul Request',
                 onPressed: () => context.push('/jobs/create', extra: {
                   'listingId': chat!.listingId,
                   'hostUid': otherUid,
                 }),
               ),
             ),
        ],
      ),
      body: Column(
        children: [
          // Messages Feed
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(color: Colors.grey[50], shape: BoxShape.circle),
                          child: Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey[200]),
                        ),
                        const SizedBox(height: 16),
                        Text('Your Secure Transmission Begins', style: TextStyle(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderUid == currentUid;
                    return _MessageBubble(message: msg, isMe: isMe);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: forestGreen)),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),

          // High-End Input Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[100]!)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), offset: const Offset(0, -4), blurRadius: 10),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6F5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.black87, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Compose message...',
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _isSending ? null : _send,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: forestGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: forestGreen.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Center(
                        child: _isSending
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper Providers
final _chatProvider = StreamProvider.autoDispose.family<Chat?, String>((ref, chatId) {
  return ref.watch(chatRepositoryProvider).watchChat(chatId);
});

final _messagesProvider = StreamProvider.autoDispose.family<List<ChatMessage>, String>((ref, chatId) {
  return ref.watch(chatRepositoryProvider).watchMessages(chatId);
});

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    const forestGreen = Color(0xFF2E7D32);
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? forestGreen : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 20),
              ),
              border: isMe ? null : Border.all(color: Colors.grey[100]!),
              boxShadow: [
                if (isMe) BoxShadow(color: forestGreen.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: Text(
              message.text,
              style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15, height: 1.4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
            child: Text(
              DateFormat.jm().format(message.sentAt),
              style: TextStyle(color: Colors.grey[400], fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
