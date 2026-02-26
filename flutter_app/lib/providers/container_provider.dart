import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/evidence_container.dart';
import '../services/container_service.dart';

final _svc = ContainerService();

class ContainersNotifier extends AsyncNotifier<List<EvidenceContainer>> {
  @override
  Future<List<EvidenceContainer>> build() => _svc.list();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_svc.list);
  }

  Future<EvidenceContainer> create(String name) async {
    final c = await _svc.create(name);
    state = AsyncData([c, ...state.valueOrNull ?? []]);
    return c;
  }

  Future<void> delete(String id) async {
    await _svc.delete(id);
    state = AsyncData(
      (state.valueOrNull ?? []).where((c) => c.id != id).toList(),
    );
  }
}

final containersProvider =
    AsyncNotifierProvider<ContainersNotifier, List<EvidenceContainer>>(
        ContainersNotifier.new);
