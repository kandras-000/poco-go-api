class User {
  final String id;
  final String username;
  final String email;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'] as String,
        username: j['username'] as String,
        email: j['email'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'created_at': createdAt.toIso8601String(),
      };
}
