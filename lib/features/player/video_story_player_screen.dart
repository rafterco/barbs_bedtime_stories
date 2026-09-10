import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:barbs_bedtime_stories/core/theme/app_colors.dart';
import 'package:barbs_bedtime_stories/core/theme/app_typography.dart';
import 'package:barbs_bedtime_stories/data/models/story.dart';
import 'package:barbs_bedtime_stories/services/audio_player_service.dart';

class VideoStoryPlayerScreen extends StatefulWidget {
  final Story? story;
  final String videoUrl;
  final String title;
  final String narrator;
  final String? coverImageUrl;
  final VoidCallback? onSwitchToAudio;
  final VoidCallback? onClose;

  const VideoStoryPlayerScreen({
    super.key,
    this.story,
    required this.videoUrl,
    required this.title,
    this.narrator = 'Barbara',
    this.coverImageUrl,
    this.onSwitchToAudio,
    this.onClose,
  });

  @override
  State<VideoStoryPlayerScreen> createState() => _VideoStoryPlayerScreenState();
}

class _VideoStoryPlayerScreenState extends State<VideoStoryPlayerScreen> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _hasError = false;
  bool _showControls = true;

  Story _getEffectiveStory() {
    if (widget.story != null) return widget.story!;
    return Story(
      id: 'barbara_video_${widget.title.hashCode}',
      title: widget.title,
      description: 'Storytime with Barbara',
      narrator: widget.narrator,
      duration: _controller?.value.duration.inSeconds ?? 360,
      category: 'Storytime',
      tags: const ['video'],
      audioUrl: widget.videoUrl,
      coverImageUrl: widget.coverImageUrl ?? '',
      videoUrl: widget.videoUrl,
      isFeatured: false,
      isPublished: true,
      playCount: 1,
      sortOrder: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  VoidCallback? _controllerListener;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    AudioPlayerService.instance.isVideoPlayerFullScreen.value = true;
    _setupVideo();
  }

  void _setupVideo() {
    final service = AudioPlayerService.instance;
    final active = service.activeVideoController;
    final effectiveStory = _getEffectiveStory();

    // If an active video controller is already running this story, reuse it cleanly
    if (active != null &&
        active.value.isInitialized &&
        service.currentStory.value?.id == effectiveStory.id) {
      _controller = active;
      _controllerListener = () {
        if (mounted) {
          service.updateVideoPlaybackState(active.value.isPlaying);
          setState(() {});
        }
      };
      _controller!.addListener(_controllerListener!);
      setState(() {
        _initialized = true;
      });
      return;
    }

    // Otherwise, stop any prior audio/video and initialize fresh
    service.stopPlayback();
    service.isVideoPlayerFullScreen.value = true;
    _initVideo();
  }

  Future<void> _initVideo() async {
    final resolved = resolveStorageUrl(widget.videoUrl);
    final uri = Uri.parse(resolved);
    final controller = VideoPlayerController.networkUrl(uri);
    _controller = controller;

    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      
      final effectiveStory = _getEffectiveStory();
      AudioPlayerService.instance.registerVideoController(
        controller,
        story: effectiveStory,
      );

      _controllerListener = () {
        if (mounted) {
          AudioPlayerService.instance.updateVideoPlaybackState(controller.value.isPlaying);
          setState(() {});
        }
      };
      controller.addListener(_controllerListener!);
      await controller.play();
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    AudioPlayerService.instance.isVideoPlayerFullScreen.value = false;
    if (_controller != null && _controllerListener != null) {
      _controller!.removeListener(_controllerListener!);
    }
    if (_isClosing) {
      AudioPlayerService.instance.stopPlayback();
    }
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    HapticFeedback.lightImpact();
    if (_controller!.value.isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }
    AudioPlayerService.instance.updateVideoPlaybackState(_controller!.value.isPlaying);
    setState(() {});
  }

  void _seekRelative(int seconds) {
    if (_controller == null) return;
    HapticFeedback.selectionClick();
    final current = _controller!.value.position;
    final target = current + Duration(seconds: seconds);
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > _controller!.value.duration
            ? _controller!.value.duration
            : target);
    _controller!.seekTo(clamped);
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _minimizePlayer() {
    _isClosing = false;
    AudioPlayerService.instance.isVideoPlayerFullScreen.value = false;
    HapticFeedback.lightImpact();
    if (widget.onClose != null) {
      widget.onClose!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  void _closePlayer() {
    _isClosing = true;
    AudioPlayerService.instance.isVideoPlayerFullScreen.value = false;
    HapticFeedback.lightImpact();
    AudioPlayerService.instance.stopPlayback();
    if (widget.onClose != null) {
      widget.onClose!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        AudioPlayerService.instance.isVideoPlayerFullScreen.value = false;
      },
      child: Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() {
              _showControls = !_showControls;
            });
          },
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null && details.primaryVelocity! > 250) {
              _minimizePlayer();
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ── Video Surface ──
              if (_initialized && !_hasError && _controller != null)
                Center(
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  ),
                )
              else if (_hasError)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.videocam_off_rounded,
                          size: 48,
                          color: AppColors.lavender,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Video story unavailable',
                          style: AppTypography.headlineMedium.copyWith(
                            color: AppColors.warmGold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'You can still listen to the audio recording in the player.',
                          style: AppTypography.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        if (widget.onSwitchToAudio != null) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.warmGold,
                              foregroundColor: AppColors.deepNavy,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            icon: const Icon(Icons.headphones_rounded, size: 18),
                            label: const Text('Listen to Audio Recording'),
                            onPressed: () async {
                              _isClosing = true;
                              await AudioPlayerService.instance.stopPlayback();
                              widget.onSwitchToAudio!();
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              else
                const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.warmGold,
                  ),
                ),

              // ── Top Header Controls ──
              if (_showControls)
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Row(
                    children: [
                      // Left: Minimize
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(36, 36),
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        tooltip: 'Minimize',
                        onPressed: _minimizePlayer,
                      ),
                      const SizedBox(width: 6),

                      // Center: Storytime badge (Expanded to guarantee no overflow)
                      Expanded(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xCC130E2E),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    AppColors.warmGold.withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '🎙️ ',
                                  style: TextStyle(fontSize: 10),
                                ),
                                Flexible(
                                  child: Text(
                                    'Storytime with Barbara',
                                    style: TextStyle(
                                      color: AppColors.warmGold,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Right: Audio Only toggle + Close button
                      if (widget.onSwitchToAudio != null) ...[
                        GestureDetector(
                          onTap: () async {
                            _isClosing = true;
                            await AudioPlayerService.instance.stopPlayback();
                            widget.onSwitchToAudio!();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xCC130E2E),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    AppColors.warmGold.withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.headphones_rounded,
                                  color: AppColors.warmGold,
                                  size: 12,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Audio',
                                  style: TextStyle(
                                    color: AppColors.warmGold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(36, 36),
                        ),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        tooltip: 'Close',
                        onPressed: _closePlayer,
                      ),
                    ],
                  ),
                ),

              // ── Bottom Progress, Controls & Title Overlay ──
              if (_showControls && _initialized && _controller != null)
                Positioned(
                  bottom: 20,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.fromLTRB(18, 14, 18, 12),
                    decoration: BoxDecoration(
                      color: const Color(0xEE130E2E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.warmGold.withValues(alpha: 0.25),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title & Narrator Row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.title,
                                    style: AppTypography.headlineMedium.copyWith(
                                      color: AppColors.moonlightWhite,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Read by ${widget.narrator}',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.lavender.withValues(alpha: 0.8),
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Progress Slider Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            height: 6,
                            child: VideoProgressIndicator(
                              _controller!,
                              allowScrubbing: true,
                              colors: const VideoProgressColors(
                                playedColor: AppColors.warmGold,
                                bufferedColor: Colors.white24,
                                backgroundColor: Colors.white12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Timestamps
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_controller!.value.position),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _formatDuration(_controller!.value.duration),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Integrated Controls Row (Rewind, Play/Pause, Forward)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              iconSize: 30,
                              padding: const EdgeInsets.all(6),
                              constraints: const BoxConstraints(),
                              icon: const Icon(
                                Icons.replay_10_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () => _seekRelative(-10),
                            ),
                            const SizedBox(width: 32),
                            GestureDetector(
                              onTap: _togglePlayPause,
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.warmGold,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.warmGold.withValues(alpha: 0.4),
                                      blurRadius: 14,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  (_controller?.value.isPlaying ?? false)
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: AppColors.deepNavy,
                                  size: 32,
                                ),
                              ),
                            ),
                            const SizedBox(width: 32),
                            IconButton(
                              iconSize: 30,
                              padding: const EdgeInsets.all(6),
                              constraints: const BoxConstraints(),
                              icon: const Icon(
                                Icons.forward_10_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () => _seekRelative(10),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
