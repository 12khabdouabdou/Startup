import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock conversations
    final conversations = [
      {'name': 'Ahmed Transport', 'lastMessage': 'On my way! ETA 10 mins', 'time': '9:30 AM', 'unread': 2},
      {'name': 'RecycleMax', 'lastMessage': 'Certificate issued', 'time': 'Yesterday', 'unread': 0},
      {'name': 'John Developer', 'lastMessage': 'Thanks for the quick service', 'time': 'Yesterday', 'unread': 0},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: ListView.builder(
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final conv = conversations[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                (conv['name'] as String)[0],
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    conv['name'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (conv['unread'] as int > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${conv['unread']} new',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
              ],
            ),
            subtitle: Text(conv['lastMessage'] as String),
            trailing: Text(
              conv['time'] as String,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            onTap: () => context.push('/chat/1'),
          );
        },
      ),
    );
  }
}
