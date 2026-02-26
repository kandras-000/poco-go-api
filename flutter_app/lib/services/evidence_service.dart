import 'dart:io';
import 'package:dio/dio.dart';
import '../models/evidence.dart';
import 'api_client.dart';

class EvidenceService {
  Future<Evidence> upload({
    required String containerId,
    required File file,
    required String filename,
    String? description,
    double? latitude,
    double? longitude,
  }) async {
    final formData = FormData.fromMap({
      'container_id': containerId,
      'file': await MultipartFile.fromFile(file.path, filename: filename),
      if (description != null && description.isNotEmpty)
        'description': description,
      if (latitude != null) 'latitude': latitude.toString(),
      if (longitude != null) 'longitude': longitude.toString(),
    });
    final res = await dio.post('/evidence', data: formData);
    return Evidence.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) => dio.delete('/evidence/$id');
}
