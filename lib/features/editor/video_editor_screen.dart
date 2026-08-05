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
import '../../core/network/api_client.dart'; // NEW: Imported to access dioProvider
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

  // --- Background Music State ---
  late AudioPlayer _bgmPlayer;
  String? _bgmUrl;
  String? _bgmTitle;
  double _bgmVolume = 0.15;
  bool _isBgmPlaying = false;

  bool _isExporting = false;

  late List<EditorClip> _videoClips;
  late List<EditorClip> _audioClips;

  bool _editingVideo = true;
  int _activeIndex = 0;

  final List<double> _speedOptions = [0.5, 1.0, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _videoClips = widget.videos.map((m) => EditorClip(m)).toList();
    _audioClips = widget.audios.map((m) => EditorClip(m)).toList();

    _audioPlayer = AudioPlayer();
    _bgmPlayer = AudioPlayer();
    _bgmPlayer.setLoopMode(LoopMode.all);

    if (_videoClips.isNotEmpty) {
      _loadPreview(true, 0);
    } else if (_audioClips.isNotEmpty) {
      _loadPreview(false, 0);
    }
  }

  String _patchNetworkUrl(String url) {
    if (url.contains('127.0.0.1') || url.contains('localhost')) {
      final base = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8001';
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

      final oldController = _videoController;
      setState(() => _videoController = null);
      if (oldController != null) {
        await oldController.dispose();
      }

      final clip = _videoClips[index];
      final vLocal = clip.media['localPath'];
      final vNet = clip.media['networkUrl'];

      final newController = vLocal != null
          ? VideoPlayerController.file(File(vLocal))
          : VideoPlayerController.networkUrl(Uri.parse(_patchNetworkUrl(vNet)));

      try {
        await newController.initialize();

        setState(() {
          _videoController = newController;
          clip.duration =
              _videoController!.value.duration.inMilliseconds / 1000.0;
          if (clip.trimEnd == 0.0) clip.trimEnd = clip.duration;
        });

        _videoController!.setVolume(1.0);
        _videoController!.setPlaybackSpeed(clip.speed);
        _videoController!.play();

        if (_bgmUrl != null && _isBgmPlaying) _bgmPlayer.play();
      } catch (e) {
        CustomSnackbar.show(
          context: context,
          message:
              "Emulator Codec Error: Preview unavailable, but file will export successfully.",
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

        if (_bgmUrl != null && _isBgmPlaying) _bgmPlayer.play();
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
      bool isNowPlaying = false;
      if (_editingVideo && _videoController != null) {
        if (_videoController!.value.isPlaying) {
          _videoController!.pause();
        } else {
          _videoController!.play();
          isNowPlaying = true;
        }
      } else {
        if (_audioPlayer.playing) {
          _audioPlayer.pause();
        } else {
          _audioPlayer.play();
          isNowPlaying = true;
        }
      }

      if (_bgmUrl != null && _isBgmPlaying) {
        isNowPlaying ? _bgmPlayer.play() : _bgmPlayer.pause();
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

  void _splitClip() {
    final activeList = _editingVideo ? _videoClips : _audioClips;
    final activeClip = activeList[_activeIndex];

    double currentPos = 0.0;
    if (_editingVideo && _videoController != null) {
      currentPos = _videoController!.value.position.inMilliseconds / 1000.0;
    } else if (!_editingVideo) {
      currentPos = _audioPlayer.position.inMilliseconds / 1000.0;
    }

    if (currentPos > activeClip.trimStart + 0.1 &&
        currentPos < activeClip.trimEnd - 0.1) {
      final newClip = EditorClip(activeClip.media)
        ..duration = activeClip.duration
        ..trimStart = currentPos
        ..trimEnd = activeClip.trimEnd
        ..speed = 1.0;

      setState(() {
        activeClip.trimEnd = currentPos;
        activeList.insert(_activeIndex + 1, newClip);
      });

      CustomSnackbar.show(
        context: context,
        message: "Clip split! You can now adjust speeds independently.",
      );
    } else {
      CustomSnackbar.show(
        context: context,
        message: "Playhead must be in the middle of the clip to split.",
        isError: true,
      );
    }
  }

  void _openMusicLibrary() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const BgmPickerSheet(),
    );

    if (result != null) {
      setState(() {
        _bgmUrl = result['url'];
        _bgmTitle = result['title'];
        _isBgmPlaying = true;
      });
      await _bgmPlayer.setUrl(_bgmUrl!);
      _bgmPlayer.setVolume(_bgmVolume);

      if ((_videoController?.value.isPlaying ?? false) ||
          _audioPlayer.playing) {
        _bgmPlayer.play();
      }
    }
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

      Map<String, String> downloadedCache = {};

      for (int i = 0; i < _videoClips.length; i++) {
        var clip = _videoClips[i];
        String path = clip.media['localPath'] ?? '';

        if (path.isEmpty) {
          final netUrl = clip.media['networkUrl'];
          if (downloadedCache.containsKey(netUrl)) {
            path = downloadedCache[netUrl]!;
          } else {
            path =
                '${tempDir.path}/v_${DateTime.now().millisecondsSinceEpoch}_$i.${clip.media['extension']}';
            await Dio().download(_patchNetworkUrl(netUrl), path);
            downloadedCache[netUrl] = path;
          }
        }

        inputs.add('-i "$path"');
        double end = clip.trimEnd > 0 ? clip.trimEnd : 99999.0;
        String pts = (1.0 / clip.speed).toString();
        filterComplex +=
            "[$inputIndex:v]trim=start=${clip.trimStart}:end=$end,setpts=PTS-STARTPTS,setpts=$pts*PTS[v$i]; ";
        videoOutputs.add("[v$i]");
        inputIndex++;
      }

      for (int i = 0; i < _audioClips.length; i++) {
        var clip = _audioClips[i];
        String path = clip.media['localPath'] ?? '';

        if (path.isEmpty) {
          final netUrl = clip.media['networkUrl'];
          if (downloadedCache.containsKey(netUrl)) {
            path = downloadedCache[netUrl]!;
          } else {
            path =
                '${tempDir.path}/a_${DateTime.now().millisecondsSinceEpoch}_$i.${clip.media['extension']}';
            await Dio().download(_patchNetworkUrl(netUrl), path);
            downloadedCache[netUrl] = path;
          }
        }

        inputs.add('-i "$path"');
        double end = clip.trimEnd > 0 ? clip.trimEnd : 99999.0;
        filterComplex +=
            "[$inputIndex:a]atrim=start=${clip.trimStart}:end=$end,asetpts=PTS-STARTPTS,atempo=${clip.speed}[a$i]; ";
        audioOutputs.add("[a$i]");
        inputIndex++;
      }

      String rawVideoMap = "";
      if (videoOutputs.length > 1) {
        filterComplex +=
            "${videoOutputs.join('')}concat=n=${videoOutputs.length}:v=1:a=0[concat_v]; ";
        rawVideoMap = "[concat_v]";
      } else {
        rawVideoMap = videoOutputs.first;
      }

      // Downscale video to 720p @ 30fps max with SAR=1 to prevent cutoff / distortion
      filterComplex +=
          "${rawVideoMap}scale='min(1280\,iw)':-2,fps=30,setsar=1[final_v]; ";
      String finalVideoMap = "[final_v]";

      String finalAudioMap = "";
      if (audioOutputs.length > 1) {
        filterComplex +=
            "${audioOutputs.join('')}concat=n=${audioOutputs.length}:v=0:a=1[base_a]; ";
        finalAudioMap = "[base_a]";
      } else {
        finalAudioMap = audioOutputs.first;
      }

      CustomSnackbar.show(context: context, message: "Rendering video...");
      final outputPath =
          '${tempDir.path}/master_export_${DateTime.now().millisecondsSinceEpoch}.mp4';

      // REMOVED -shortest: Prevents cutting off the last video segment when audio ends earlier
      String command =
          '${inputs.join(' ')} -filter_complex "$filterComplex" -map "$finalVideoMap" -map "$finalAudioMap" -c:v libx264 -preset ultrafast -crf 28 -pix_fmt yuv420p -threads 0 -c:a aac -b:a 128k "$outputPath"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        CustomSnackbar.show(
          context: context,
          message: "Export complete! Uploading to AI...",
        );

        final projectId = await ref
            .read(projectControllerProvider.notifier)
            .submitProject(
              name: widget.projectName,
              type: 'audio_replace',
              filePath: outputPath,
              bgmUrl: (_isBgmPlaying && _bgmUrl != null) ? _bgmUrl : null,
              bgmVolume: (_isBgmPlaying && _bgmUrl != null) ? _bgmVolume : null,
            );

        if (projectId != null && mounted) {
          context.pushReplacement('/processing/$projectId');
        } else {
          final error = ref.read(projectControllerProvider).error;
          if (mounted) {
            CustomSnackbar.show(
              context: context,
              message: error ?? "Upload failed",
              isError: true,
            );
          }
        }
      } else {
        if (mounted) {
          CustomSnackbar.show(
            context: context,
            message: "Failed to render video locally.",
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context: context,
          message: "Export error: $e",
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer.dispose();
    _bgmPlayer.dispose();
    super.dispose();
  }

  Widget _buildToolButton(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.textGrey.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
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
          Expanded(
            flex: 3,
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
                    Expanded(
                      child: Text(
                        "Editing: ${activeClip.media['name']}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildToolButton(
                      Icons.content_cut,
                      "Split",
                      _splitClip,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 12),
                    _buildToolButton(
                      Icons.speed,
                      "Speed: ${activeClip.speed}x",
                      _changeActiveSpeed,
                      color: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                    onChanged: (vals) => setState(() {
                      activeClip.trimStart = vals.start;
                      activeClip.trimEnd = vals.end;
                    }),
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
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              color: AppColors.background,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        "Video Sequence",
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 12,
                        ),
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
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 12,
                        ),
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
                    const SizedBox(height: 24),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        "Background Music",
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _bgmUrl == null
                          ? OutlinedButton.icon(
                              onPressed: _openMusicLibrary,
                              icon: const Icon(
                                Icons.music_note,
                                color: Colors.white,
                              ),
                              label: const Text(
                                "Add Background Music",
                                style: TextStyle(color: Colors.white),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: BorderSide(
                                  color: AppColors.textGrey.withOpacity(0.3),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.cards,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.greenAccent.withOpacity(0.5),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              _isBgmPlaying
                                                  ? Icons.pause_circle_filled
                                                  : Icons.play_circle_filled,
                                              color: Colors.greenAccent,
                                            ),
                                            onPressed: () {
                                              setState(
                                                () => _isBgmPlaying =
                                                    !_isBgmPlaying,
                                              );
                                              _isBgmPlaying
                                                  ? _bgmPlayer.play()
                                                  : _bgmPlayer.pause();
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            width: 150,
                                            child: Text(
                                              _bgmTitle ?? "BGM Track",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.search,
                                              color: AppColors.textGrey,
                                              size: 20,
                                            ),
                                            onPressed: _openMusicLibrary,
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.redAccent,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              _bgmPlayer.stop();
                                              setState(() {
                                                _bgmUrl = null;
                                                _bgmTitle = null;
                                                _isBgmPlaying = false;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.volume_down,
                                        color: AppColors.textGrey,
                                        size: 16,
                                      ),
                                      Expanded(
                                        child: Slider(
                                          activeColor: Colors.greenAccent,
                                          inactiveColor: AppColors.textGrey
                                              .withOpacity(0.2),
                                          value: _bgmVolume,
                                          min: 0.0,
                                          max: 1.0,
                                          onChanged: (val) {
                                            setState(() => _bgmVolume = val);
                                            _bgmPlayer.setVolume(val);
                                          },
                                        ),
                                      ),
                                      Text(
                                        "${(_bgmVolume * 100).toInt()}%",
                                        style: const TextStyle(
                                          color: AppColors.textGrey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
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

// FIX: Changed from StatefulWidget to ConsumerStatefulWidget to access Riverpod's mocked Dio
class BgmPickerSheet extends ConsumerStatefulWidget {
  const BgmPickerSheet({super.key});

  @override
  ConsumerState<BgmPickerSheet> createState() => _BgmPickerSheetState();
}

class _BgmPickerSheetState extends ConsumerState<BgmPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  final AudioPlayer _previewPlayer = AudioPlayer();

  bool _isLoading = false;
  List<dynamic> _tracks = [];
  String? _currentlyPreviewingUrl;

  @override
  void initState() {
    super.initState();
    _searchJamendo("cinematic");
  }

  Future<void> _searchJamendo(String query) async {
    setState(() => _isLoading = true);
    try {
      final clientId = dotenv.env['JAMENDO_CLIENT_ID'] ?? '56d30c95';

      // FIX: Replace standard Dio() with the injected dioProvider to intercept the test calls
      final response = await ref
          .read(dioProvider)
          .get(
            'https://api.jamendo.com/v3.0/tracks/',
            queryParameters: {
              'client_id': clientId,
              'format': 'json',
              'limit': 15,
              'tags': query.toLowerCase(),
            },
          );

      if (response.data['headers'] != null &&
          response.data['headers']['status'] == 'failed') {
        throw Exception(response.data['headers']['error_message']);
      }

      setState(() => _tracks = response.data['results'] ?? []);
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context: context,
          message: "API Error: ${e.toString().replaceAll('Exception: ', '')}",
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _togglePreview(String url) async {
    if (_currentlyPreviewingUrl == url && _previewPlayer.playing) {
      await _previewPlayer.pause();
      setState(() {});
    } else {
      setState(() => _currentlyPreviewingUrl = url);
      await _previewPlayer.setUrl(url);
      _previewPlayer.play();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _previewPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Music Library (Jamendo)",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Search mood (e.g. Upbeat, Lo-Fi)...",
              hintStyle: const TextStyle(color: AppColors.textGrey),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search, color: AppColors.primary),
                onPressed: () => _searchJamendo(_searchController.text),
              ),
              filled: true,
              fillColor: AppColors.cards,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: _searchJamendo,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _tracks.isEmpty
                ? const Center(
                    child: Text(
                      "No tracks found.",
                      style: TextStyle(color: AppColors.textGrey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _tracks.length,
                    itemBuilder: (ctx, i) {
                      final track = _tracks[i];
                      final title = track['name'] ?? 'Unknown Track';
                      final url = track['audio'];
                      final artist = track['artist_name'] ?? 'Unknown Artist';
                      final isPlayingThis =
                          _currentlyPreviewingUrl == url &&
                          _previewPlayer.playing;

                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.textGrey.withOpacity(0.1),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                isPlayingThis
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_fill,
                                color: AppColors.accent,
                                size: 36,
                              ),
                              onPressed: () => _togglePreview(url),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    artist,
                                    style: const TextStyle(
                                      color: AppColors.textGrey,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                _previewPlayer.stop();
                                Navigator.pop(context, <String, dynamic>{
                                  'url': url.toString(),
                                  'title': title.toString(),
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  "Select",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
