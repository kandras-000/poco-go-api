import '../models/evidence_container.dart';
import '../models/evidence.dart';
import 'api_client.dart';

class ContainerService {
  Future<List<EvidenceContainer>> list() async {
    final res = await dio.get('/containers');
    return (res.data as List)
        .map((e) => EvidenceContainer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<EvidenceContainer> create(String name) async {
    final res = await dio.post('/containers', data: {'name': name});
    return EvidenceContainer.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) => dio.delete('/containers/$id');

  Future<List<Evidence>> listEvidence(String containerId) async {
    final res = await dio.get('/containers/$containerId/evidence');
    return (res.data as List)
        .map((e) => Evidence.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
