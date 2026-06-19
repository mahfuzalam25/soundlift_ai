import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/action_card.dart';
import '../../shared/dialogs/custom_snackbar.dart'; // Import our new utility

class CreateScreen extends StatelessWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Create New Project",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Choose the type of enhancement you need.",
              style: TextStyle(color: AppColors.textGrey, fontSize: 16),
            ),
            const SizedBox(height: 32),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.0,
              children: [
                ActionCard(
                  title: "Audio\nEnhancement",
                  icon: Icons.multitrack_audio,
                  onTap: () => context.push('/upload?type=audio-enhance'),
                ),
                ActionCard(
                  title: "Video\nEnhancement",
                  icon: Icons.video_settings,
                  onTap: () => context.push('/upload?type=video-enhance'),
                ),
                ActionCard(
                  title: "Replace Video\nAudio",
                  icon: Icons.mic_external_on,
                  onTap: () => context.push('/upload?type=audio-replace'),
                ),
                Opacity(
                  opacity: 0.5,
                  child: ActionCard(
                    title: "AI Subtitles\n(Coming Soon)",
                    icon: Icons.subtitles,
                    onTap: () {
                      // Using our new CustomSnackbar
                      CustomSnackbar.show(
                        context: context,
                        message: 'AI Subtitles are coming in a future update!',
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
