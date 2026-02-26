class Evidence {
  final String id;
  final String userId;
  final String? containerId;
  final String filename;
  final String originalName;
  final String mimeType;
  final int fileSize;
  final String? description;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  const Evidence({
    required this.id,
    required this.userId,
    this.containerId,
    required this.filename,
    required this.originalName,
    required this.mimeType,
    required this.fileSize,
    this.description,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  factory Evidence.fromJson(Map<String, dynamic> j) => Evidence(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        containerId: j['container_id'] as String?,
        filename: j['filename'] as String,
        originalName: j['original_name'] as String,
        mimeType: j['mime_type'] as String,
        fileSize: (j['file_size'] as num).toInt(),
        description: j['description'] as String?,
        latitude: (j['latitude'] as num?)?.toDouble(),
        longitude: (j['longitude'] as num?)?.toDouble(),
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  bool get hasLocation => latitude != null && longitude != null;
  bool get isImage => mimeType.startsWith('image/');
  bool get isVideo => mimeType.startsWith('video/');
  bool get isAudio => mimeType.startsWith('audio/');
}
