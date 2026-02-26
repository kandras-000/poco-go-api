import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _controller;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  String? _token;
  bool _disposed = false;

  Stream<Map<String, dynamic>> connect(String token) {
    _token = token;
    _disposed = false;
    _controller = StreamController<Map<String, dynamic>>.broadcast();
    _connect();
    return _controller!.stream;
  }

  void _connect() {
    if (_disposed) return;
    try {
      final uri = Uri.parse('$kWsUrl?token=$_token');
      _channel = WebSocketChannel.connect(uri);
      _channel!.stream.listen(
        (data) {
          final decoded = jsonDecode(data as String) as Map<String, dynamic>;
          _controller?.add(decoded);
        },
        onDone: _onDisconnect,
        onError: (_) => _onDisconnect(),
      );
      _startPing();
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _onDisconnect() {
    _pingTimer?.cancel();
    if (!_disposed) _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 2), _connect);
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      try {
        _channel?.sink.add('ping');
      } catch (_) {}
    });
  }

  void dispose() {
    _disposed = true;
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _controller?.close();
  }
}
