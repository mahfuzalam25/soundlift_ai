import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/dialogs/custom_snackbar.dart';
import '../projects/providers/project_provider.dart';
import '../../core/services/ad_service.dart';
import '../subscription/providers/subscription_provider.dart';

class ProcessingScreen extends ConsumerStatefulWidget {
  final String jobId;
  const ProcessingScreen({super.key, required this.jobId});

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectControllerProvider.notifier).startPolling(widget.jobId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final projectState = ref.watch(projectControllerProvider);

    bool isCompleted = projectState.status == 'completed';
    bool isFailed = projectState.status == 'failed';

    ref.listen<ProjectState>(projectControllerProvider, (previous, next) {
      if (previous?.status != 'completed' && next.status == 'completed') {
        CustomSnackbar.show(context: context, message: "Processing Complete!");
      } else if (previous?.status != 'failed' && next.status == 'failed') {
        CustomSnackbar.show(
          context: context,
          message: next.error ?? "Processing Failed.",
          isError: true,
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Container(
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: AppColors.cards,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isCompleted
                        ? "Success!"
                        : isFailed
                        ? "Failed"
                        : "Processing",
                    style: TextStyle(
                      color: isFailed ? Colors.redAccent : Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isCompleted
                        ? "Your media is ready to view!"
                        : isFailed
                        ? "Something went wrong during processing."
                        : "Please wait while we process your file.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textGrey),
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    height: 120,
                    width: 120,
                    child: isCompleted
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                            size: 100,
                          )
                        : isFailed
                        ? const Icon(
                            Icons.error,
                            color: Colors.redAccent,
                            size: 100,
                          )
                        : CircularProgressIndicator(
                            value: projectState.progress / 100.0,
                            strokeWidth: 8,
                            backgroundColor: AppColors.background,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),

                  if (!isCompleted && !isFailed) ...[
                    Text(
                      "${projectState.progress}%",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Status: ${projectState.status.toUpperCase()}",
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (!isCompleted)
                        TextButton(
                          onPressed: () {
                            ref
                                .read(projectControllerProvider.notifier)
                                .stopPolling();
                            context.pop();
                          },
                          child: Text(
                            isFailed ? "Go Back" : "Cancel",
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ElevatedButton(
                        onPressed: () {
                          ref
                              .read(projectControllerProvider.notifier)
                              .stopPolling();

                          if (isCompleted) {
                            // NEW: Evaluate Free Plan Ad Interception
                            final sub = ref.read(mySubscriptionProvider).value;
                            if (sub != null &&
                                sub.planName.toLowerCase() == 'free') {
                              AdService.showInterstitialWithLoader(
                                context,
                                onComplete: () {
                                  if (mounted)
                                    context.pushReplacement(
                                      '/project/${widget.jobId}',
                                    );
                                },
                              );
                            } else {
                              context.pushReplacement(
                                '/project/${widget.jobId}',
                              );
                            }
                          } else {
                            context.go('/dashboard');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.background,
                          minimumSize: const Size(0, 56),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        child: Text(
                          isCompleted ? "View Result" : "Run in Background",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
