import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/dialogs/custom_snackbar.dart';
import '../projects/providers/project_provider.dart';

class EditorClip {
  final Map<String, dynamic> media;
  double trimStart = 0.0;
  double trimEnd = 0.0;
  double speed = 1.0;
  double duration = 0.0;

  EditorClip(this.media);
}

class VideoEditorScreen extends ConsumerStatefulWidget {
  final String projectName;
  final List<Map<String, dynamic>> videos;
  final List<Map<String, dynamic>> audios;

  const VideoEditorScreen({
    super.key,
    required this.projectName,
    required this.videos,
    required this.audios,
  });

  @override
  ConsumerState<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends ConsumerState<VideoEditorScreen> {
  VideoPlayerController? _videoController;
  late AudioPlayer _audioPlayer;

  bool _isExporting = false;

  late List<EditorClip> _videoClips;
  late List<EditorClip> _audioClips;

  bool _editingVideo =
      true;
  int _activeIndex = 0;

  final List<double> _speedOptions = [0.5, 1.0, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _videoClips = widget.videos.map((m) => EditorClip(m)).toList();
    _audioClips = widget.audios.map((m) => EditorClip(m)).toList();
    _audioPlayer = AudioPlayer();

    if (_videoClips.isNotEmpty) {
      _loadPreview(true, 0);
    } else if (_audioClips.isNotEmpty) {
      _loadPreview(false, 0);
    }
  }

  String _patchNetworkUrl(String url) {
    if (url.contains('127.0.0.1') || url.contains('localhost')) {
      final base = dotenv.env['API_BASE_URL'] ?? 'http://192.168.0.105:8001';
      final uri = Uri.parse(base);
      return url
          .replaceAll('127.0.0.1:8001', '${uri.host}:${uri.port}')
          .replaceAll('localhost:8001', '${uri.host}:${uri.port}');
    }
    return url;
  }

  Future<void> _loadPreview(bool isVideoTrack, int index) async {
    setState(() {
      _editingVideo = isVideoTrack;
      _activeIndex = index;
    });

    if (isVideoTrack) {
      await _audioPlayer.pause();
      if (_videoController != null) await _videoController!.dispose();

      final clip = _videoClips[index];
      final vLocal = clip.media['localPath'];
      final vNet = clip.media['networkUrl'];

      _videoController = vLocal != null
          ? VideoPlayerController.file(File(vLocal))
          : VideoPlayerController.networkUrl(Uri.parse(_patchNetworkUrl(vNet)));

      try {
        await _videoController!.initialize();

        // Initialize duration bounds
        setState(() {
          clip.duration =
              _videoController!.value.duration.inMilliseconds / 1000.0;
          if (clip.trimEnd == 0.0) clip.trimEnd = clip.duration;
        });

        _videoController!.setVolume(1.0);
        _videoController!.setPlaybackSpeed(clip.speed);
        _videoController!.play();
      } catch (e) {
        CustomSnackbar.show(
          context: context,
          message:
              "Emulator Codec Error: Preview unavailable, but file will still export successfully.",
          isError: true,
        );
      }
    } else {
      _videoController?.pause();
      final clip = _audioClips[index];
      final aLocal = clip.media['localPath'];
      final aNet = clip.media['networkUrl'];

      try {
        if (aLocal != null) {
          await _audioPlayer.setFilePath(aLocal);
        } else {
          await _audioPlayer.setUrl(_patchNetworkUrl(aNet));
        }

        setState(() {
          clip.duration = (_audioPlayer.duration?.inMilliseconds ?? 0) / 1000.0;
          if (clip.trimEnd == 0.0) clip.trimEnd = clip.duration;
        });

        _audioPlayer.setSpeed(clip.speed);
        _audioPlayer.play();
      } catch (e) {
        CustomSnackbar.show(
          context: context,
          message: "Error loading audio preview.",
          isError: true,
        );
      }
    }
  }

  void _togglePlayPause() {
    setState(() {
      if (_editingVideo && _videoController != null) {
        _videoController!.value.isPlaying
            ? _videoController!.pause()
            : _videoController!.play();
      } else {
        _audioPlayer.playing ? _audioPlayer.pause() : _audioPlayer.play();
      }
    });
  }

  void _changeActiveSpeed() {
    setState(() {
      final clip = _editingVideo
          ? _videoClips[_activeIndex]
          : _audioClips[_activeIndex];
      int currentIndex = _speedOptions.indexOf(clip.speed);
      clip.speed = _speedOptions[(currentIndex + 1) % _speedOptions.length];

      if (_editingVideo && _videoController != null) {
        _videoController!.setPlaybackSpeed(clip.speed);
      } else {
        _audioPlayer.setSpeed(clip.speed);
      }
    });
  }

  Future<void> _handleExport() async {
    if (_videoClips.isEmpty || _audioClips.isEmpty) {
      CustomSnackbar.show(
        context: context,
        message: "Add at least one video and one audio clip.",
        isError: true,
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final tempDir = await getTemporaryDirectory();
      CustomSnackbar.show(context: context, message: "Fetching media...");

      List<String> inputs = [];
      int inputIndex = 0;
      String filterComplex = "";
      List<String> videoOutputs = [];
      List<String> audioOutputs = [];

      // Process Videos
      for (int i = 0; i < _videoClips.length; i++) {
        var clip = _videoClips[i];
        String path = clip.media['localPath'] ?? '';
        if (path.isEmpty) {
          path =
              '${tempDir.path}/v_${DateTime.now().millisecondsSinceEpoch}_$i.${clip.media['extension']}';
          await Dio().download(
            _patchNetworkUrl(clip.media['networkUrl']),
            path,
          );
        }
        inputs.add('-i "$path"');

        // Apply trims and speed. Video uses 'setpts'
        double end = clip.trimEnd > 0
            ? clip.trimEnd
            : 99999.0;
        String pts = (1.0 / clip.speed).toString();

        filterComplex +=
            "[$inputIndex:v]trim=start=${clip.trimStart}:end=$end,setpts=PTS-STARTPTS,setpts=$pts*PTS[v$i]; ";
        videoOutputs.add("[v$i]");
        inputIndex++;
      }

      // Process Audios
      for (int i = 0; i < _audioClips.length; i++) {
        var clip = _audioClips[i];
        String path = clip.media['localPath'] ?? '';
        if (path.isEmpty) {
          path =
              '${tempDir.path}/a_${DateTime.now().millisecondsSinceEpoch}_$i.${clip.media['extension']}';
          await Dio().download(
            _patchNetworkUrl(clip.media['networkUrl']),
            path,
          );
        }
        inputs.add('-i "$path"');

        // Apply trims and speed. Audio uses 'atempo'
        double end = clip.trimEnd > 0 ? clip.trimEnd : 99999.0;

        filterComplex +=
            "[$inputIndex:a]atrim=start=${clip.trimStart}:end=$end,asetpts=PTS-STARTPTS,atempo=${clip.speed}[a$i]; ";
        audioOutputs.add("[a$i]");
        inputIndex++;
      }

      // Concat Graphs
      String finalVideoMap = "";
      if (videoOutputs.length > 1) {
        filterComplex +=
            "${videoOutputs.join('')}concat=n=${videoOutputs.length}:v=1:a=0[outv]; ";
        finalVideoMap = "[outv]";
      } else {
        finalVideoMap = videoOutputs.first;
      }

      String finalAudioMap = "";
      if (audioOutputs.length > 1) {
        filterComplex +=
            "${audioOutputs.join('')}concat=n=${audioOutputs.length}:v=0:a=1[outa]";
        finalAudioMap = "[outa]";
      } else {
        finalAudioMap = audioOutputs.first;
      }

      CustomSnackbar.show(
        context: context,
        message: "Rendering final video...",
      );
      final outputPath =
          '${tempDir.path}/master_export_${DateTime.now().millisecondsSinceEpoch}.mp4';

      // Final Command Assembly
      String command =
          '${inputs.join(' ')} -filter_complex "$filterComplex" -map "$finalVideoMap" -map "$finalAudioMap" -c:v libx264 -c:a aac -shortest "$outputPath"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        CustomSnackbar.show(
          context: context,
          message: "Export complete! Uploading...",
        );

        final projectId = await ref
            .read(projectControllerProvider.notifier)
            .submitProject(
              name: widget.projectName,
              type: 'audio_replace',
              filePath: outputPath,
            );

        if (projectId != null && mounted) {
          context.pushReplacement('/processing/$projectId');
        } else {
          final error = ref.read(projectControllerProvider).error;
          if (mounted)
            CustomSnackbar.show(
              context: context,
              message: error ?? "Upload failed",
              isError: true,
            );
        }
      } else {
        if (mounted)
          CustomSnackbar.show(
            context: context,
            message: "Failed to render video locally.",
            isError: true,
          );
      }
    } catch (e) {
      if (mounted)
        CustomSnackbar.show(
          context: context,
          message: "Export error: $e",
          isError: true,
        );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    EditorClip activeClip = _editingVideo
        ? _videoClips[_activeIndex]
        : _audioClips[_activeIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cards,
        title: const Text("Video NLE Editor", style: TextStyle(fontSize: 16)),
        actions: [
          _isExporting
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _handleExport,
                  child: const Text(
                    "Export",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ],
      ),
      body: Column(
        children: [
          // Preview Player
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child: _editingVideo
                  ? (_videoController == null ||
                            !_videoController!.value.isInitialized)
                        ? const Center(
                            child: Icon(
                              Icons.video_file,
                              color: AppColors.textGrey,
                              size: 64,
                            ),
                          )
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              AspectRatio(
                                aspectRatio:
                                    _videoController!.value.aspectRatio,
                                child: VideoPlayer(_videoController!),
                              ),
                              if (!_videoController!.value.isPlaying)
                                IconButton(
                                  iconSize: 64,
                                  icon: const Icon(
                                    Icons.play_circle_fill,
                                    color: Colors.white70,
                                  ),
                                  onPressed: _togglePlayPause,
                                ),
                            ],
                          )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.graphic_eq,
                            color: AppColors.accent,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          IconButton(
                            iconSize: 64,
                            icon: Icon(
                              _audioPlayer.playing
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                              color: Colors.white70,
                            ),
                            onPressed: _togglePlayPause,
                          ),
                        ],
                      ),
                    ),
            ),
          ),

          // Active Clip Controls
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: AppColors.cards,
              border: Border(
                bottom: BorderSide(color: AppColors.textGrey.withOpacity(0.1)),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Editing: ${activeClip.media['name']}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    TextButton(
                      onPressed: _changeActiveSpeed,
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "${activeClip.speed}x",
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Active Clip Trimmer
                if (activeClip.duration > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Start: ${activeClip.trimStart.toStringAsFixed(1)}s",
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        "End: ${activeClip.trimEnd.toStringAsFixed(1)}s",
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  RangeSlider(
                    activeColor: _editingVideo
                        ? AppColors.primary
                        : AppColors.accent,
                    inactiveColor: AppColors.textGrey.withOpacity(0.2),
                    values: RangeValues(
                      activeClip.trimStart,
                      activeClip.trimEnd,
                    ),
                    min: 0.0,
                    max: activeClip.duration,
                    onChanged: (vals) {
                      setState(() {
                        activeClip.trimStart = vals.start;
                        activeClip.trimEnd = vals.end;
                      });
                    },
                  ),
                ] else
                  const Text(
                    "Select clip to load duration...",
                    style: TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),

          // Multi-Track Selector
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              color: AppColors.background,
              child: ListView(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      "Video Sequence",
                      style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _videoClips.length,
                      itemBuilder: (ctx, i) => _buildClipCard(
                        _videoClips[i].media['name'],
                        Icons.video_file,
                        AppColors.primary,
                        isActive: _editingVideo && _activeIndex == i,
                        onTap: () => _loadPreview(true, i),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      "Audio Sequence",
                      style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _audioClips.length,
                      itemBuilder: (ctx, i) => _buildClipCard(
                        _audioClips[i].media['name'],
                        Icons.audio_file,
                        AppColors.accent,
                        isActive: !_editingVideo && _activeIndex == i,
                        onTap: () => _loadPreview(false, i),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClipCard(
    String name,
    IconData icon,
    Color color, {
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.2) : AppColors.cards,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? color : color.withOpacity(0.3),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              name,
              style: const TextStyle(fontSize: 10, color: Colors.white),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
