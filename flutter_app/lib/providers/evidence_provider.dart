import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/evidence.dart';
import '../services/container_service.dart';
import '../services/evidence_service.dart';

final _containerSvc = ContainerService();
final _evidenceSvc = EvidenceService();

class EvidenceNotifier
    extends FamilyAsyncNotifier<List<Evidence>, String> {
  @override
  Future<List<Evidence>> build(String arg) =>
      _containerSvc.listEvidence(arg);

  Future<void> refresh(String containerId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _containerSvc.listEvidence(containerId));
  }

  Future<void> upload({
    required String containerId,
    required File file,
    required String filename,
    String? description,
    double? latitude,
    double? longitude,
  }) async {
    final evidence = await _evidenceSvc.upload(
      containerId: containerId,
      file: file,
      filename: filename,
      description: description,
      latitude: latitude,
      longitude: longitude,
    );
    state = AsyncData([evidence, ...state.valueOrNull ?? []]);
  }

  Future<void> delete(String id) async {
    await _evidenceSvc.delete(id);
    state = AsyncData(
      (state.valueOrNull ?? []).where((e) => e.id != id).toList(),
    );
  }
}

final evidenceProvider =
    AsyncNotifierProviderFamily<EvidenceNotifier, List<Evidence>, String>(
        EvidenceNotifier.new);
