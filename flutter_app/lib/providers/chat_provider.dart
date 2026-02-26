import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/message.dart';
import '../services/message_service.dart';
import '../services/websocket_service.dart';
import '../services/api_client.dart';

final _msgSvc = MessageService();

// ── Users ──────────────────────────────────────────────────────────────────

final usersProvider = FutureProvider<List<User>>((ref) => _msgSvc.listUsers());

// ── Messages per conversation ──────────────────────────────────────────────

class MessagesNotifier extends FamilyAsyncNotifier<List<Message>, String> {
  @override
  Future<List<Message>> build(String arg) =>
      _msgSvc.fetchHistory(arg);

  Future<void> send(String recipientId, String content) async {
    final msg = await _msgSvc.send(recipientId, content);
    state = AsyncData([...(state.valueOrNull ?? []), msg]);
  }

  void push(Message msg) {
    state = AsyncData([...state.valueOrNull ?? [], msg]);
  }
}

final messagesProvider =
    AsyncNotifierProviderFamily<MessagesNotifier, List<Message>, String>(
        MessagesNotifier.new);

// ── WebSocket ──────────────────────────────────────────────────────────────

final _wsService = WebSocketService();

final wsProvider = StreamProvider<Map<String, dynamic>>((ref) async* {
  final token = await readToken();
  if (token == null) return;

  await for (final event in _wsService.connect(token)) {
    yield event;
  }

  ref.onDispose(_wsService.dispose);
});
