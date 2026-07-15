import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart' as fp;
import '../../core/theme/app_colors.dart';
import '../../shared/buttons/primary_button.dart';
import '../../shared/dialogs/custom_snackbar.dart';
import '../projects/providers/project_provider.dart';

class ReplaceAudioUploadScreen extends ConsumerStatefulWidget {
  const ReplaceAudioUploadScreen({super.key});

  @override
  ConsumerState<ReplaceAudioUploadScreen> createState() =>
      _ReplaceAudioUploadScreenState();
}

class _ReplaceAudioUploadScreenState
    extends ConsumerState<ReplaceAudioUploadScreen> {
  final List<Map<String, dynamic>> _videoMediaList = [];
  final List<Map<String, dynamic>> _audioMediaList = [];
  final TextEditingController _nameController = TextEditingController();

  Future<void> _pickLocalFile(bool isVideo) async {
    try {
      fp.FilePickerResult? result = await fp.FilePicker.pickFiles(
        type: fp.FileType.custom,
        allowMultiple: true,
        allowedExtensions: isVideo ? ['mp4', 'mov'] : ['mp3', 'wav', 'm4a'],
      );

      if (result != null) {
        setState(() {
          for (var file in result.files) {
            final mediaData = {
              'name': file.name,
              'localPath': file.path,
              'networkUrl': null,
              'extension': file.extension ?? (isVideo ? 'mp4' : 'mp3'),
              'size': file.size,
            };

            if (isVideo) {
              _videoMediaList.add(mediaData);
              if (_nameController.text.isEmpty) {
                _nameController.text = file.name.split('.').first;
              }
            } else {
              _audioMediaList.add(mediaData);
            }
          }
        });
      }
    } catch (e) {
      if (mounted)
        CustomSnackbar.show(
          context: context,
          message: "Failed to pick file.",
          isError: true,
        );
    }
  }

  Future<void> _handleSelectExisting(bool isVideo) async {
    try {
      final projects = await ref.read(projectListProvider.future);
      final filtered = projects.where((p) {
        if (p['status'] != 'completed') return false;
        final format =
            p['media_file']?['format']?.toString().toLowerCase() ?? '';
        final isVideoFormat = ['mp4', 'mov', 'avi', 'mkv'].contains(format);
        return isVideo ? isVideoFormat : !isVideoFormat;
      }).toList();

      if (filtered.isEmpty && mounted) {
        CustomSnackbar.show(
          context: context,
          message: "No completed projects found.",
        );
        return;
      }

      if (mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: AppColors.cards,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final p = filtered[i];
              return ListTile(
                leading: Icon(
                  isVideo ? Icons.video_file : Icons.audio_file,
                  color: AppColors.primary,
                ),
                title: Text(
                  p['project_name'],
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  final mediaInfo = p['media_file'];
                  final mediaData = {
                    'name': p['project_name'],
                    'localPath': null,
                    'networkUrl':
                        mediaInfo['processed_file'] ??
                        mediaInfo['original_file'],
                    'extension': mediaInfo['format'],
                    'size': mediaInfo['media_size'] ?? 0,
                  };
                  setState(() {
                    if (isVideo) {
                      _videoMediaList.add(mediaData);
                      if (_nameController.text.isEmpty)
                        _nameController.text = p['project_name'];
                    } else {
                      _audioMediaList.add(mediaData);
                    }
                  });
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        );
      }
    } catch (e) {
      if (mounted)
        CustomSnackbar.show(
          context: context,
          message: "Failed to load projects.",
          isError: true,
        );
    }
  }

  void _submit() {
    if (_nameController.text.isEmpty) {
      CustomSnackbar.show(
        context: context,
        message: "Please enter a project name",
        isError: true,
      );
      return;
    }
    if (_videoMediaList.isEmpty) {
      CustomSnackbar.show(
        context: context,
        message: "Add at least one video",
        isError: true,
      );
      return;
    }
    if (_audioMediaList.isEmpty) {
      CustomSnackbar.show(
        context: context,
        message: "Add at least one audio file",
        isError: true,
      );
      return;
    }

    context.pushReplacement(
      '/editor/video',
      extra: {
        'projectName': _nameController.text,
        'videos': _videoMediaList,
        'audios': _audioMediaList,
      },
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (bytes.toString().length - 1) ~/ 3;
    return "${(bytes / (1024 * i > 0 ? 1024 * i : 1)).toStringAsFixed(2)} ${suffixes[i]}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Media Library", style: TextStyle(fontSize: 16)),
        backgroundColor: AppColors.cards,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Project Name",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "E.g., Final Cut Vlog",
                hintStyle: const TextStyle(color: AppColors.textGrey),
                filled: true,
                fillColor: AppColors.cards,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Video Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "1. Videos",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.cloud_download,
                        color: AppColors.primary,
                      ),
                      onPressed: () => _handleSelectExisting(true),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle,
                        color: AppColors.primary,
                      ),
                      onPressed: () => _pickLocalFile(true),
                    ),
                  ],
                ),
              ],
            ),
            ..._videoMediaList.asMap().entries.map(
              (e) => _buildFileCard(
                e.value,
                Icons.video_file,
                () => setState(() => _videoMediaList.removeAt(e.key)),
              ),
            ),
            if (_videoMediaList.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "No videos added.",
                  style: TextStyle(color: AppColors.textGrey),
                ),
              ),
            const SizedBox(height: 32),

            // Audio Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "2. Audio Tracks",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.cloud_download,
                        color: AppColors.accent,
                      ),
                      onPressed: () => _handleSelectExisting(false),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle,
                        color: AppColors.accent,
                      ),
                      onPressed: () => _pickLocalFile(false),
                    ),
                  ],
                ),
              ],
            ),
            ..._audioMediaList.asMap().entries.map(
              (e) => _buildFileCard(
                e.value,
                Icons.audio_file,
                () => setState(() => _audioMediaList.removeAt(e.key)),
              ),
            ),
            if (_audioMediaList.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "No audio tracks added.",
                  style: TextStyle(color: AppColors.textGrey),
                ),
              ),

            const SizedBox(height: 48),
            PrimaryButton(text: "Continue to Editor", onPressed: _submit),
          ],
        ),
      ),
    );
  }

  Widget _buildFileCard(
    Map<String, dynamic> media,
    IconData icon,
    VoidCallback onRemove,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  media['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Size: ${_formatBytes(media['size'])}",
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.redAccent),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
