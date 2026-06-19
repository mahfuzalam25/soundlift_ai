import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class VideoEditorScreen extends StatelessWidget {
  final String projectId;
  const VideoEditorScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cards,
        title: const Text("Video Editor", style: TextStyle(fontSize: 16)),
        actions: [
          IconButton(icon: const Icon(Icons.undo), onPressed: () {}),
          IconButton(icon: const Icon(Icons.redo), onPressed: () {}),
          TextButton(
            onPressed: () {
              // Show Export Dialog
            },
            child: const Text("Export", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Area: Video Preview Player
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child: const Center(
                child: Icon(Icons.play_circle_outline, color: Colors.white54, size: 64),
              ),
            ),
          ),
          
          // Middle Area: Editor Controls
          Container(
            height: 60,
            color: AppColors.cards,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(icon: const Icon(Icons.content_cut, color: Colors.white), onPressed: () {}), // Trim
                IconButton(icon: const Icon(Icons.volume_up, color: Colors.white), onPressed: () {}), // Volume
                IconButton(icon: const Icon(Icons.music_note, color: Colors.white), onPressed: () {}), // Add Audio
                IconButton(icon: const Icon(Icons.volume_off, color: Colors.redAccent), onPressed: () {}), // Mute Original
              ],
            ),
          ),
          
          // Bottom Area: Timeline
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: AppColors.background,
              child: ListView(
                children: [
                  _buildTimelineTrack("Video Track", AppColors.primary, Icons.video_file),
                  const SizedBox(height: 8),
                  _buildTimelineTrack("Original Audio", AppColors.textGrey, Icons.audio_file),
                  const SizedBox(height: 8),
                  _buildTimelineTrack("AI Enhanced Audio", AppColors.success, Icons.auto_awesome),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTrack(String title, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Container(
            width: 80,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cards,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(height: 4),
                Text(title, style: const TextStyle(fontSize: 10, color: Colors.white), textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.5)),
              ),
              child: Center(
                child: Text("00:00 - 05:30", style: TextStyle(color: color, fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}