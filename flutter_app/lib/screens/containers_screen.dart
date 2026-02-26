import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/container_provider.dart';
import '../models/evidence_container.dart';

class ContainersScreen extends ConsumerWidget {
  const ContainersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final containersAsync = ref.watch(containersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Case Builder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Chat',
            onPressed: () => context.go('/chat'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: containersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (containers) => containers.isEmpty
            ? _EmptyState(onCreate: () => _showCreateSheet(context, ref))
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(containersProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: containers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) =>
                      _ContainerTile(container: containers[i]),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Container'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _CreateContainerSheet(
        onCreate: (name) async {
          final c =
              await ref.read(containersProvider.notifier).create(name);
          if (context.mounted) {
            Navigator.pop(context);
            context.go('/evidence/${c.id}');
          }
        },
      ),
    );
  }
}

class _ContainerTile extends ConsumerWidget {
  final EvidenceContainer container;
  const _ContainerTile({required this.container});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.folder_outlined,
              color: Color(0xFF4F46E5), size: 28),
        ),
        title: Text(container.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(_formatDate(container.createdAt),
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chevron_right, color: Colors.grey),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.redAccent, size: 20),
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ),
        onTap: () => context.go('/evidence/${container.id}'),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete container?'),
        content: Text(
            'Delete "${container.name}" and all its evidence? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(containersProvider.notifier).delete(container.id);
    }
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.folder_open, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No evidence containers yet.',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Create a container to start organising your evidence.',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onCreate,
            child: const Text('Create your first container'),
          ),
        ],
      ),
    );
  }
}

class _CreateContainerSheet extends StatefulWidget {
  final Future<void> Function(String name) onCreate;
  const _CreateContainerSheet({required this.onCreate});

  @override
  State<_CreateContainerSheet> createState() => _CreateContainerSheetState();
}

class _CreateContainerSheetState extends State<_CreateContainerSheet> {
  final _ctrl = TextEditingController();
  bool _creating = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      await widget.onCreate(name);
    } catch (e) {
      setState(() {
        _creating = false;
        _error = 'Failed to create container';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New Evidence Container',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            autofocus: true,
            maxLength: 255,
            decoration: const InputDecoration(
                hintText: 'Container name…', counterText: ''),
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child:
                  Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _creating ? null : _submit,
                  child: _creating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Create'),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
