import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../models/user.dart';
import '../models/message.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  User? _selectedUser;

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);
    final currentUser = ref.watch(authProvider).valueOrNull;
    final isWide = MediaQuery.of(context).size.width > 600;

    // Listen to WebSocket and push messages into the right notifier
    ref.listen(wsProvider, (_, next) {
      next.whenData((event) {
        if (event['type'] == 'message') {
          final msg = Message.fromJson(
              event['data'] as Map<String, dynamic>);
          final peerId = msg.senderId == currentUser?.id
              ? msg.recipientId
              : msg.senderId;
          ref.read(messagesProvider(peerId).notifier).push(msg);
        }
      });
    });

    final userList = usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (users) {
        final others = users
            .where((u) => u.id != currentUser?.id)
            .toList();
        if (others.isEmpty) {
          return const Center(
              child: Text('No other users yet.',
                  style: TextStyle(color: Colors.grey)));
        }
        return ListView.separated(
          itemCount: others.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final u = others[i];
            final selected = _selectedUser?.id == u.id;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFEEF2FF),
                child: Text(
                  u.username[0].toUpperCase(),
                  style: const TextStyle(
                      color: Color(0xFF4F46E5),
                      fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(u.username),
              selected: selected,
              selectedTileColor: const Color(0xFFEEF2FF),
              onTap: () => setState(() => _selectedUser = u),
            );
          },
        );
      },
    );

    if (isWide) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: Row(
          children: [
            SizedBox(width: 280, child: userList),
            const VerticalDivider(width: 1),
            Expanded(
              child: _selectedUser == null
                  ? const Center(
                      child: Text('Select a user to start chatting'))
                  : _MessageThread(
                      peer: _selectedUser!, currentUserId: currentUser?.id ?? ''),
            ),
          ],
        ),
      );
    }

    if (_selectedUser != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_selectedUser!.username),
          leading: BackButton(
              onPressed: () => setState(() => _selectedUser = null)),
        ),
        body: _MessageThread(
            peer: _selectedUser!, currentUserId: currentUser?.id ?? ''),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: userList,
    );
  }
}

class _MessageThread extends ConsumerStatefulWidget {
  final User peer;
  final String currentUserId;
  const _MessageThread(
      {required this.peer, required this.currentUserId});

  @override
  ConsumerState<_MessageThread> createState() => _MessageThreadState();
}

class _MessageThreadState extends ConsumerState<_MessageThread> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    await ref
        .read(messagesProvider(widget.peer.id).notifier)
        .send(widget.peer.id, text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.peer.id));

    return Column(
      children: [
        Expanded(
          child: messagesAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (messages) {
              _scrollToBottom();
              if (messages.isEmpty) {
                return const Center(
                    child: Text('No messages yet.',
                        style: TextStyle(color: Colors.grey)));
              }
              return ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                itemCount: messages.length,
                itemBuilder: (_, i) => _Bubble(
                  message: messages[i],
                  isMine: messages[i].senderId == widget.currentUserId,
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: EdgeInsets.fromLTRB(
              12, 8, 12, MediaQuery.of(context).viewInsets.bottom + 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: const InputDecoration(
                    hintText: 'Type a message…',
                    isDense: true,
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send, color: Color(0xFF4F46E5)),
                onPressed: _send,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  final Message message;
  final bool isMine;
  const _Bubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMine
              ? const Color(0xFF4F46E5)
              : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMine)
              Text(
                message.senderUsername,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4F46E5)),
              ),
            Text(
              message.content,
              style: TextStyle(
                  color: isMine ? Colors.white : Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
