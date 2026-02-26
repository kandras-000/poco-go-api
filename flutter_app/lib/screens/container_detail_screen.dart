import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/evidence_provider.dart';
import '../models/evidence.dart';
import '../config.dart';

class ContainerDetailScreen extends ConsumerStatefulWidget {
  final String containerId;
  const ContainerDetailScreen({super.key, required this.containerId});

  @override
  ConsumerState<ContainerDetailScreen> createState() =>
      _ContainerDetailScreenState();
}

class _ContainerDetailScreenState
    extends ConsumerState<ContainerDetailScreen> {
  File? _selectedFile;
  String? _selectedFilename;
  final _descCtrl = TextEditingController();
  bool _useLocation = false;
  String _locationStatus = '';
  double? _latitude;
  double? _longitude;
  bool _uploading = false;
  double? _uploadProgress;
  String? _uploadError;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.camera);
    if (img != null) _setFile(File(img.path), img.name);
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final img = await picker.pickMedia();
    if (img != null) _setFile(File(img.path), img.name);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'mp3', 'wav', 'm4a', 'aac'],
    );
    if (result?.files.single.path != null) {
      _setFile(
          File(result!.files.single.path!), result.files.single.name);
    }
  }

  void _setFile(File f, String name) {
    setState(() {
      _selectedFile = f;
      _selectedFilename = name;
      _uploadError = null;
    });
  }

  Future<void> _toggleLocation() async {
    if (_useLocation) {
      setState(() {
        _useLocation = false;
        _latitude = null;
        _longitude = null;
        _locationStatus = '';
      });
      return;
    }
    setState(() => _locationStatus = 'Getting location…');
    try {
      bool svcEnabled = await Geolocator.isLocationServiceEnabled();
      if (!svcEnabled) {
        setState(() => _locationStatus = 'Location services disabled');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() => _locationStatus = 'Permission denied');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );
      setState(() {
        _useLocation = true;
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        _locationStatus =
            '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
      });
    } catch (e) {
      setState(() => _locationStatus = 'Location unavailable');
    }
  }

  Future<void> _upload() async {
    if (_selectedFile == null) return;
    setState(() {
      _uploading = true;
      _uploadError = null;
      _uploadProgress = 0;
    });
    try {
      await ref.read(evidenceProvider(widget.containerId).notifier).upload(
            containerId: widget.containerId,
            file: _selectedFile!,
            filename: _selectedFilename!,
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
            latitude: _latitude,
            longitude: _longitude,
          );
      setState(() {
        _selectedFile = null;
        _selectedFilename = null;
        _descCtrl.clear();
        _useLocation = false;
        _latitude = null;
        _longitude = null;
        _locationStatus = '';
        _uploadProgress = null;
      });
    } catch (e) {
      setState(() => _uploadError = 'Upload failed. Please try again.');
    } finally {
      setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final evidenceAsync = ref.watch(evidenceProvider(widget.containerId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evidence'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(evidenceProvider(widget.containerId).notifier)
            .refresh(widget.containerId),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildUploadCard()),
            evidenceAsync.when(
              loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SliverToBoxAdapter(
                  child: Center(child: Text('Error: $e'))),
              data: (items) => items.isEmpty
                  ? const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 48),
                        child: Center(
                            child: Text('No evidence yet.',
                                style: TextStyle(color: Colors.grey))),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.all(12),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.75,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) =>
                              _EvidenceCard(evidence: items[i], containerId: widget.containerId),
                          childCount: items.length,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard() {
    return Card(
      margin: const EdgeInsets.all(12),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upload Evidence',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            // Pick buttons
            Row(
              children: [
                _PickButton(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: _pickFromCamera),
                const SizedBox(width: 8),
                _PickButton(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: _pickFromGallery),
                const SizedBox(width: 8),
                _PickButton(
                    icon: Icons.attach_file,
                    label: 'File',
                    onTap: _pickFile),
              ],
            ),

            // Selected file indicator
            if (_selectedFile != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: Color(0xFF4F46E5), size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _selectedFilename ?? '',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      _selectedFile = null;
                      _selectedFilename = null;
                    }),
                    child: const Icon(Icons.close,
                        size: 16, color: Colors.grey),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                hintText: 'Description (optional)',
                isDense: true,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            // Location toggle
            InkWell(
              onTap: _toggleLocation,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Switch(
                      value: _useLocation,
                      onChanged: (_) => _toggleLocation(),
                      activeColor: const Color(0xFF4F46E5),
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(width: 8),
                    const Text('Include location'),
                    if (_locationStatus.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _locationStatus,
                          style: TextStyle(
                            fontSize: 12,
                            color: _useLocation
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            if (_uploadError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_uploadError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),

            if (_uploadProgress != null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (_selectedFile == null || _uploading) ? null : _upload,
                child: _uploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Upload Evidence'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PickButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF4F46E5),
          side: const BorderSide(color: Color(0xFF4F46E5)),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        ),
      ),
    );
  }
}

class _EvidenceCard extends ConsumerWidget {
  final Evidence evidence;
  final String containerId;
  const _EvidenceCard({required this.evidence, required this.containerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Preview
          Expanded(
            child: evidence.isImage
                ? CachedNetworkImage(
                    imageUrl: '$kUploadsUrl/${evidence.filename}',
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.broken_image, color: Colors.grey),
                  )
                : Container(
                    color: const Color(0xFFF3F4F6),
                    child: Icon(
                      evidence.isVideo
                          ? Icons.videocam
                          : evidence.isAudio
                              ? Icons.audiotrack
                              : evidence.mimeType.contains('pdf')
                                  ? Icons.picture_as_pdf
                                  : Icons.insert_drive_file,
                      size: 48,
                      color: const Color(0xFF4F46E5),
                    ),
                  ),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evidence.originalName,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                if (evidence.description != null &&
                    evidence.description!.isNotEmpty)
                  Text(
                    evidence.description!,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                if (evidence.hasLocation)
                  GestureDetector(
                    onTap: () => _openMaps(evidence.latitude!,
                        evidence.longitude!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '📍 ${evidence.latitude!.toStringAsFixed(4)}, ${evidence.longitude!.toStringAsFixed(4)}',
                        style: const TextStyle(
                            fontSize: 9, color: Color(0xFF166534)),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Delete
          InkWell(
            onTap: () => _confirmDelete(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: const Color(0xFFFEF2F2),
              child: const Center(
                child: Text('Delete',
                    style: TextStyle(fontSize: 11, color: Colors.red)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openMaps(double lat, double lon) async {
    final uri =
        Uri.parse('https://www.google.com/maps?q=$lat,$lon');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete evidence?'),
        content: Text(
            'Delete "${evidence.originalName}"? This cannot be undone.'),
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
      await ref
          .read(evidenceProvider(containerId).notifier)
          .delete(evidence.id);
    }
  }
}
