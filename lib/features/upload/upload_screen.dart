import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart' as fp;
import '../../core/theme/app_colors.dart';
import '../../shared/buttons/primary_button.dart';
import '../../shared/widgets/upload_dropzone.dart';
import '../../shared/dialogs/custom_snackbar.dart';

class UploadScreen extends StatefulWidget {
  final String type;
  const UploadScreen({super.key, required this.type});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  // FIXED: Added fp. prefix here
  fp.PlatformFile? _selectedFile;

  Future<void> _pickFile() async {
    try {
      // FIXED: Removed '.platform' for version 11.0.2 compatibility
      fp.FilePickerResult? result = await fp.FilePicker.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'mp4', 'mov'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
        });

        if (mounted) {
          CustomSnackbar.show(
            context: context,
            message: "File loaded: ${_selectedFile!.name}",
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context: context,
          message: "Failed to pick file. Please try again.",
          isError: true,
        );
      }
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
    });
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
        title: const Text("Upload Media", style: TextStyle(fontSize: 16)),
        backgroundColor: AppColors.cards,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Upload your files",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Fast and easy way",
              style: TextStyle(color: AppColors.textGrey, fontSize: 16),
            ),
            const SizedBox(height: 40),

            if (_selectedFile == null)
              UploadDropzone(onTap: _pickFile)
            else
              _buildSelectedFileCard(),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    CustomSnackbar.show(
                      context: context,
                      message: "Audio recording coming soon",
                    );
                  },
                  icon: const Icon(Icons.mic, color: Colors.white),
                  label: const Text(
                    "Record Audio",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    CustomSnackbar.show(
                      context: context,
                      message: "Video recording coming soon",
                    );
                  },
                  icon: const Icon(Icons.videocam, color: Colors.white),
                  label: const Text(
                    "Record Video",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                  ),
                ),
              ],
            ),

            const Spacer(),

            PrimaryButton(
              text: "Submit for Processing",
              onPressed: _selectedFile == null
                  ? () => CustomSnackbar.show(
                      context: context,
                      message: "Please select a file first",
                      isError: true,
                    )
                  : () => context.push('/processing/job-123'),
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
          const Icon(
            Icons.insert_drive_file,
            size: 48,
            color: AppColors.accent,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFile!.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
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
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
              size: 20,
            ),
            label: const Text(
              "Remove File",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
