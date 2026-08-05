import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import 'support_provider.dart';
import '../../shared/dialogs/custom_snackbar.dart';

class TutorialsScreen extends ConsumerWidget {
  const TutorialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tutorialsAsync = ref.watch(tutorialsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cards,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          "Tutorials",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: tutorialsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(
          child: Text(
            "Error: $err",
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
        data: (tutorials) {
          if (tutorials.isEmpty)
            return const Center(
              child: Text(
                "No tutorials available",
                style: TextStyle(color: AppColors.textGrey),
              ),
            );

          return ListView.builder(
            padding: const EdgeInsets.all(24.0),
            itemCount: tutorials.length,
            itemBuilder: (context, index) {
              final tutorial = tutorials[index];
              return GestureDetector(
                onTap: () {
                  if (tutorial.youtubeId != null) {
                    context.push(
                      '/help/tutorials/player/${tutorial.youtubeId}',
                    );
                  } else {
                    CustomSnackbar.show(
                      context: context,
                      message: "Invalid video link",
                      isError: true,
                    );
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.cards,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.textGrey.withOpacity(0.1),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 180,
                            width: double.infinity,
                            color: AppColors.background,
                            child: tutorial.youtubeId != null
                                ? Image.network(
                                    'https://img.youtube.com/vi/${tutorial.youtubeId}/hqdefault.jpg',
                                    fit: BoxFit.cover,
                                    // FIX: Added errorBuilder to handle missing network in test environments gracefully
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.video_library,
                                              size: 64,
                                              color: AppColors.textGrey,
                                            ),
                                  )
                                : const Icon(
                                    Icons.video_library,
                                    size: 64,
                                    color: AppColors.textGrey,
                                  ),
                          ),
                          Container(
                            height: 180,
                            width: double.infinity,
                            color: Colors.black.withOpacity(0.3),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tutorial.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              tutorial.description,
                              style: const TextStyle(
                                color: AppColors.textGrey,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
