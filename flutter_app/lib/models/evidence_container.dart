class EvidenceContainer {
  final String id;
  final String userId;
  final String name;
  final DateTime createdAt;

  const EvidenceContainer({
    required this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
  });

  factory EvidenceContainer.fromJson(Map<String, dynamic> j) =>
      EvidenceContainer(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        name: j['name'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
