import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart' as fp;
import '../../core/theme/app_colors.dart';
import '../../shared/buttons/primary_button.dart';
import '../../shared/widgets/upload_dropzone.dart';
import '../../shared/dialogs/custom_snackbar.dart';
import '../projects/providers/project_provider.dart';

class UploadScreen extends ConsumerStatefulWidget {
  final String type;
  const UploadScreen({super.key, required this.type});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  fp.PlatformFile? _selectedFile;
  final TextEditingController _nameController = TextEditingController();

  List<String> get _allowedExtensions {
    if (widget.type == 'audio_enhancement') return ['mp3', 'wav', 'm4a'];
    if (widget.type == 'video_enhancement') return ['mp4', 'mov', 'avi', 'mkv'];
    if (widget.type == 'audio_replace') return ['mp4', 'mov', 'avi', 'mkv'];
    return ['mp3', 'wav', 'mp4', 'mov'];
  }

  Future<void> _pickFile() async {
    try {
      fp.FilePickerResult? result = await fp.FilePicker.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: _allowedExtensions,
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
          if (_nameController.text.isEmpty) {
            _nameController.text = _selectedFile!.name.split('.').first;
          }
        });
        if (mounted) CustomSnackbar.show(context: context, message: "File loaded: ${_selectedFile!.name}");
      }
    } catch (e) {
      if (mounted) CustomSnackbar.show(context: context, message: "Failed to pick file.", isError: true);
    }
  }

  void _removeFile() {
    setState(() => _selectedFile = null);
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (bytes.toString().length - 1) ~/ 3;
    return "${(bytes / (1024 * i > 0 ? 1024 * i : 1)).toStringAsFixed(2)} ${suffixes[i]}";
  }

  Future<void> _submitProject() async {
    if (_nameController.text.isEmpty) {
      CustomSnackbar.show(context: context, message: "Please enter a project name.", isError: true);
      return;
    }
    if (_selectedFile == null) {
      CustomSnackbar.show(context: context, message: "Please select a file first", isError: true);
      return;
    }

    final projectId = await ref.read(projectControllerProvider.notifier).submitProject(
      name: _nameController.text,
      type: widget.type,
      filePath: _selectedFile!.path!,
    );

    if (projectId != null && mounted) {
      context.pushReplacement('/processing/$projectId');
    } else {
      final error = ref.read(projectControllerProvider).error;
      if (mounted && error != null) {
        CustomSnackbar.show(context: context, message: error, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectState = ref.watch(projectControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Upload Media", style: TextStyle(fontSize: 16)),
        backgroundColor: AppColors.cards,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Project Details",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Project Name",
                labelStyle: const TextStyle(color: AppColors.textGrey),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppColors.primary),
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.cards,
              ),
            ),
            const SizedBox(height: 24),

            if (_selectedFile == null)
              UploadDropzone(onTap: _pickFile)
            else
              _buildSelectedFileCard(),

            const SizedBox(height: 40),

            projectState.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : PrimaryButton(
                    text: "Submit for Processing",
                    onPressed: _submitProject,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.insert_drive_file, size: 48, color: AppColors.accent),
          const SizedBox(height: 16),
          Text(
            _selectedFile!.name,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            "Size: ${_formatBytes(_selectedFile!.size)}  •  Format: ${_selectedFile!.extension?.toUpperCase() ?? 'UNKNOWN'}",
            style: const TextStyle(color: AppColors.textGrey, fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _removeFile,
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
            label: const Text("Remove File", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}