class Message {
  final String id;
  final String senderId;
  final String senderUsername;
  final String recipientId;
  final String content;
  final bool delivered;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.senderId,
    required this.senderUsername,
    required this.recipientId,
    required this.content,
    required this.delivered,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> j) => Message(
        id: j['id'] as String,
        senderId: j['sender_id'] as String,
        senderUsername: j['sender_username'] as String,
        recipientId: j['recipient_id'] as String,
        content: j['content'] as String,
        delivered: j['delivered'] as bool,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
