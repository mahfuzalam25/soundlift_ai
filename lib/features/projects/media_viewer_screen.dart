import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/buttons/primary_button.dart';
import 'providers/project_provider.dart';

class MediaViewerScreen extends ConsumerStatefulWidget {
  final String projectId;
  const MediaViewerScreen({super.key, required this.projectId});

  @override
  ConsumerState<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends ConsumerState<MediaViewerScreen> {
  bool _isShowingProcessed = true;

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(projectDetailsProvider(widget.projectId));

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
          "Project Overview",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: projectAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(
          child: Text(
            "Error: $err",
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
        data: (project) {
          final media = project['media_file'];
          final format = media['format']?.toString().toLowerCase() ?? 'mp4';
          final isVideo = ['mp4', 'mov', 'avi', 'mkv'].contains(format);

          final originalUrl = media['original_file'];
          final processedUrl = media['processed_file'];

          final currentUrl = _isShowingProcessed ? processedUrl : originalUrl;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project['project_name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Format: ${format.toUpperCase()}",
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                // Before / After Toggle Buttons
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        text: "Original",
                        isGradient: !_isShowingProcessed,
                        onPressed: () =>
                            setState(() => _isShowingProcessed = false),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: PrimaryButton(
                        text: "Enhanced",
                        isGradient: _isShowingProcessed,
                        onPressed: () {
                          if (processedUrl != null) {
                            setState(() => _isShowingProcessed = true);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Player Area
                if (currentUrl == null)
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.cards,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        "Media not available",
                        style: TextStyle(color: AppColors.textGrey),
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.textGrey.withOpacity(0.2),
                      ),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: isVideo
                        ? CustomVideoPlayer(
                            key: ValueKey(currentUrl),
                            url: currentUrl,
                          )
                        : CustomAudioPlayer(
                            key: ValueKey(currentUrl),
                            url: currentUrl,
                          ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Custom Video Player Widget
class CustomVideoPlayer extends StatefulWidget {
  final String url;
  const CustomVideoPlayer({super.key, required this.url});

  @override
  State<CustomVideoPlayer> createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<CustomVideoPlayer> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() {}); // Update UI when ready
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          VideoPlayer(_controller),
          Center(
            child: IconButton(
              iconSize: 64,
              icon: Icon(
                _controller.value.isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                color: Colors.white.withOpacity(0.8),
              ),
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
            ),
          ),
          VideoProgressIndicator(
            _controller,
            allowScrubbing: true,
            colors: const VideoProgressColors(playedColor: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// Custom Audio Player Widget
class CustomAudioPlayer extends StatefulWidget {
  final String url;
  const CustomAudioPlayer({super.key, required this.url});

  @override
  State<CustomAudioPlayer> createState() => _CustomAudioPlayerState();
}

class _CustomAudioPlayerState extends State<CustomAudioPlayer> {
  late AudioPlayer _player;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.setUrl(widget.url);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: AppColors.cards,
      child: Column(
        children: [
          const Icon(Icons.graphic_eq, size: 64, color: AppColors.accent),
          const SizedBox(height: 24),
          StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (context, snapshot) {
              final playerState = snapshot.data;
              final isPlaying = playerState?.playing ?? false;
              return IconButton(
                iconSize: 64,
                icon: Icon(
                  isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: AppColors.primary,
                ),
                onPressed: () {
                  isPlaying ? _player.pause() : _player.play();
                },
              );
            },
          ),
          StreamBuilder<Duration?>(
            stream: _player.durationStream,
            builder: (context, snapshot) {
              final duration = snapshot.data ?? Duration.zero;
              return StreamBuilder<Duration>(
                stream: _player.positionStream,
                builder: (context, posSnapshot) {
                  var position = posSnapshot.data ?? Duration.zero;
                  if (position > duration) position = duration;
                  return Slider(
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.textGrey.withOpacity(0.2),
                    value: position.inMilliseconds.toDouble(),
                    max: duration.inMilliseconds > 0
                        ? duration.inMilliseconds.toDouble()
                        : 1.0,
                    onChanged: (val) {
                      _player.seek(Duration(milliseconds: val.toInt()));
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
