import '../models/message.dart';
import '../models/user.dart';
import 'api_client.dart';

class MessageService {
  Future<List<User>> listUsers() async {
    final res = await dio.get('/users');
    return (res.data as List)
        .map((e) => User.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Message>> fetchHistory(String userId) async {
    final res = await dio.get('/messages/$userId');
    return (res.data as List)
        .map((e) => Message.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Message> send(String recipientId, String content) async {
    final res = await dio.post('/messages',
        data: {'recipient_id': recipientId, 'content': content});
    return Message.fromJson(res.data as Map<String, dynamic>);
  }
}
