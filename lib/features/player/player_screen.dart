import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';

import 'package:barbs_bedtime_stories/core/theme/app_colors.dart';
import 'package:barbs_bedtime_stories/core/theme/app_typography.dart';
import 'package:barbs_bedtime_stories/data/models/playlist.dart';
import 'package:barbs_bedtime_stories/data/models/story.dart';
import 'package:barbs_bedtime_stories/data/providers.dart';
import 'package:barbs_bedtime_stories/services/ambient_sound_service.dart';
import 'package:barbs_bedtime_stories/services/audio_player_service.dart';
import 'package:barbs_bedtime_stories/services/download_service.dart';
import 'package:barbs_bedtime_stories/services/favorites_service.dart';
import 'package:barbs_bedtime_stories/features/player/widgets/sleep_timer_sheet.dart';
import 'package:barbs_bedtime_stories/features/player/video_story_player_screen.dart';
import 'package:barbs_bedtime_stories/widgets/ambient_sound_mixer.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final String storyId;

  const PlayerScreen({
    super.key,
    required this.storyId,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  final AudioPlayerService _audioService = AudioPlayerService.instance;
  Story? _story;
  bool _isLoading = true;
  String? _error;
  bool _isFavourite = false;
  bool _isDownloaded = false;
  bool _isDownloading = false;
  bool _audioOnly = false;

  @override
  void initState() {
    super.initState();
    _loadStory();
    _audioService.currentStory.addListener(_onCurrentStoryChanged);
  }

  @override
  void dispose() {
    _audioService.currentStory.removeListener(_onCurrentStoryChanged);
    super.dispose();
  }

  void _onCurrentStoryChanged() {
    final active = _audioService.currentStory.value;
    if (active != null && active.id != _story?.id && mounted) {
      final isFav = FavoritesService.instance.isFavorite(active.id);
      setState(() {
        _story = active;
        _isFavourite = isFav;
      });
      DownloadService.instance.isDownloaded(active.id).then((val) {
        if (mounted) setState(() => _isDownloaded = val);
      });
    }
  }

  Future<void> _loadStory() async {
    try {
      final repository = ref.read(storyRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);
      final story = await repository.getStoryById(widget.storyId);

      if (!mounted) return;

      if (story != null) {
        final isFav = FavoritesService.instance.isFavorite(story.id);
        setState(() {
          _story = story;
          _isFavourite = isFav;
          _isLoading = false;
        });

        // Check if downloaded offline
        final isDownloaded = await DownloadService.instance.isDownloaded(story.id);
        if (mounted) {
          setState(() => _isDownloaded = isDownloaded);
        }

        if (story.isVideo && !_audioOnly) {
          // Pause background audio so video sound plays clearly
          _audioService.pause();
          // Track play count
          repository.incrementPlayCount(story.id);
          // Track recently played
          userRepo.addRecentPlay(
            'anonymous',
            story.id,
            Duration.zero,
          );
        } else {
          // Only start from beginning if this story isn't already active/playing
          final isAlreadyActive = _audioService.currentStory.value?.id == story.id;
          if (!isAlreadyActive) {
            // Play via global service (handles background playback)
            await _audioService.playStory(story);

            // Track play count
            repository.incrementPlayCount(story.id);

            // Track recently played
            userRepo.addRecentPlay(
              'anonymous',
              story.id,
              Duration.zero,
            );
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Story not found';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading story: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _showSleepTimerSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const SleepTimerSheet(),
    ).then((value) {
      if (value != null && mounted) {
        _audioService.setSleepTimer(value);

        String message;
        if (value == 0) {
          message = 'Sleep timer off';
        } else if (value == -1) {
          message = 'Sleep timer: end of story';
        } else {
          message = 'Sleep timer: $value minutes';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.moonlightWhite),
            ),
            backgroundColor: AppColors.surfaceLight,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    });
  }

  void _showAmbientMixer() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const AmbientSoundMixer(),
    );
  }

  void _showPlaylistQueueSheet() {
    HapticFeedback.mediumImpact();
    final playlist = _audioService.currentPlaylist.value;
    if (playlist == null) return;
    final queue = _audioService.playlistQueueNotifier.value;
    if (queue.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.deepNavy,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.warmGold.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.queue_music_rounded, color: AppColors.warmGold, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              playlist.title,
                              style: AppTypography.headlineSmall.copyWith(
                                color: AppColors.moonlightWhite,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${queue.length} Bedtime Stories in Sequence',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.lavender,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.lavender),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.surfaceLight, height: 1),
                // List of stories in queue
                Expanded(
                  child: ValueListenableBuilder<int>(
                    valueListenable: _audioService.currentQueueIndexNotifier,
                    builder: (_, currentIndex, __) {
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: queue.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, idx) {
                          final itemStory = queue[idx];
                          final isPlayingThis = idx == currentIndex;
                          final mins = itemStory.duration ~/ 60;
                          final secs = itemStory.duration % 60;
                          final durStr = '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
                          return InkWell(
                            onTap: () {
                              Navigator.of(ctx).pop();
                              if (!isPlayingThis) {
                                _audioService.playPlaylist(queue, startIndex: idx, playlist: playlist);
                              }
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              decoration: BoxDecoration(
                                color: isPlayingThis
                                    ? AppColors.warmGold.withValues(alpha: 0.16)
                                    : AppColors.surfaceLight.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isPlayingThis
                                      ? AppColors.warmGold.withValues(alpha: 0.55)
                                      : Colors.transparent,
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Track Index or Animated Speaker
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isPlayingThis
                                          ? AppColors.warmGold
                                          : AppColors.surfaceLight,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: isPlayingThis
                                          ? const Icon(
                                              Icons.volume_up_rounded,
                                              color: AppColors.deepNavy,
                                              size: 17,
                                            )
                                          : Text(
                                              '${idx + 1}',
                                              style: AppTypography.labelSmall.copyWith(
                                                color: AppColors.lavender,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          itemStory.title,
                                          style: AppTypography.bodyMedium.copyWith(
                                            color: isPlayingThis
                                                ? AppColors.warmGold
                                                : AppColors.moonlightWhite,
                                            fontWeight: isPlayingThis
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Narrated by ${itemStory.narrator} • $durStr',
                                          style: AppTypography.labelSmall.copyWith(
                                            color: AppColors.lavender.withValues(alpha: 0.75),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isPlayingThis)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.warmGold.withValues(alpha: 0.22),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'NOW PLAYING',
                                        style: AppTypography.labelSmall.copyWith(
                                          color: AppColors.warmGold,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 9,
                                          letterSpacing: 0.5,
                                        ),
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleFavourite() async {
    HapticFeedback.mediumImpact();
    if (_story == null) return;
    final isFav = await FavoritesService.instance.toggleFavorite(_story!.id);
    if (mounted) {
      setState(() {
        _isFavourite = isFav;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFav
                ? '❤️ Added "${_story!.title}" to Favourites'
                : 'Removed "${_story!.title}" from Favourites',
            style: const TextStyle(color: Colors.white),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.surfaceLight,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _shareStory() {
    HapticFeedback.lightImpact();
    if (_story == null) return;
    Share.share(
      '🌙 Listen to "${_story!.title}" on Barbara\'s Sleep Stories!\nhttps://barbs-bedtime-stories-landing.vercel.app/#stories',
    );
  }

  Future<void> _toggleDownload() async {
    HapticFeedback.lightImpact();
    if (_story == null) return;
    final dl = DownloadService.instance;

    if (_isDownloaded) {
      await dl.removeDownload(_story!.id);
      if (mounted) setState(() => _isDownloaded = false);
    } else {
      if (mounted) setState(() => _isDownloading = true);
      await dl.downloadStory(_story!);
      if (mounted) {
        setState(() {
          _isDownloaded = true;
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.deepNavy,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.warmGold),
        ),
      );
    }

    if (_error != null || _story == null) {
      return Scaffold(
        backgroundColor: AppColors.deepNavy,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textPrimary,
              size: 32,
            ),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Text(
            _error ?? 'Unknown error',
            style: AppTypography.bodyLarge,
          ),
        ),
      );
    }

    final story = _story!;

    if (story.isVideo && !_audioOnly) {
      return VideoStoryPlayerScreen(
        story: story,
        videoUrl: story.effectiveVideoUrl,
        title: story.title,
        narrator: story.narrator,
        coverImageUrl: story.coverImageUrl,
        onSwitchToAudio: () async {
          setState(() {
            _audioOnly = true;
          });
          await _audioService.playStory(story);
        },
        onClose: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: Stack(
        children: [
          // ── Background Atmospheric Ambient Glow ──
          if (story.coverImageUrl.isNotEmpty)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Transform.scale(
                  scale: 1.15,
                  child: CachedNetworkImage(
                    imageUrl: story.coverImageUrl,
                    memCacheWidth: 60,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const SizedBox.shrink(),
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

          // ── Wind Down & Deepening Gradient Overlay ──
          ValueListenableBuilder<int?>(
            valueListenable: _audioService.sleepTimerMinutes,
            builder: (context, timerMins, _) {
              final isWindDown = timerMins != null && timerMins > 0;
              return AnimatedContainer(
                duration: const Duration(seconds: 2),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isWindDown
                        ? [
                            AppColors.deepNavy.withValues(alpha: 0.92),
                            AppColors.deepNavy.withValues(alpha: 0.95),
                            const Color(0xFF060914),
                          ]
                        : [
                            AppColors.deepNavy.withValues(alpha: 0.85),
                            AppColors.deepNavy.withValues(alpha: 0.65),
                            AppColors.deepNavy.withValues(alpha: 0.96),
                          ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              );
            },
          ),

          // ── Wind Down Star Drift Ambient Effect ──
          const Positioned.fill(
            child: IgnorePointer(
              child: _WindDownStars(),
            ),
          ),

          // ── Foreground Content ──
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── App Bar ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      // Back / Collapse button
                      _PlayerGlassButton(
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.moonlightWhite,
                          size: 26,
                        ),
                        tooltip: 'Minimize to Home',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.go('/');
                        },
                      ),
                      const Spacer(),
                      
                      // Ambient Sound Mixer button
                      ValueListenableBuilder<List<AmbientSound>>(
                        valueListenable: AmbientSoundService.instance.activeSounds,
                        builder: (context, activeSounds, _) {
                          final hasActive = activeSounds.isNotEmpty;
                          return _PlayerGlassButton(
                            icon: Icon(
                              Icons.music_note_rounded,
                              color: hasActive
                                  ? AppColors.warmGold
                                  : AppColors.moonlightWhite,
                              size: 20,
                            ),
                            isActive: hasActive,
                            tooltip: 'Ambient Sounds',
                            onTap: _showAmbientMixer,
                          );
                        },
                      ),
                      const SizedBox(width: 8),

                      // Download button
                      _PlayerGlassButton(
                        icon: _isDownloading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.warmGold,
                                ),
                              )
                            : Icon(
                                _isDownloaded
                                    ? Icons.download_done_rounded
                                    : Icons.download_rounded,
                                color: _isDownloaded
                                    ? AppColors.warmGold
                                    : AppColors.moonlightWhite,
                                size: 20,
                              ),
                        isActive: _isDownloaded,
                        tooltip: _isDownloaded ? 'Downloaded' : 'Download Story',
                        onTap: _isDownloading ? null : _toggleDownload,
                      ),
                      const SizedBox(width: 8),

                      // Share button
                      _PlayerGlassButton(
                        icon: const Icon(
                          Icons.share_rounded,
                          color: AppColors.moonlightWhite,
                          size: 19,
                        ),
                        tooltip: 'Share',
                        onTap: _shareStory,
                      ),
                      const SizedBox(width: 8),

                      // Favourite button
                      _PlayerGlassButton(
                        icon: Icon(
                          _isFavourite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: _isFavourite
                              ? AppColors.warmGold
                              : AppColors.moonlightWhite,
                          size: 20,
                        ),
                        isActive: _isFavourite,
                        tooltip: _isFavourite ? 'In Favourites' : 'Add to Favourites',
                        onTap: _toggleFavourite,
                      ),
                    ],
                  ),
                ),

                // ── Crisp Center Album Artwork Card ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 36.0,
                      vertical: 12.0,
                    ),
                    child: Center(
                      child: Hero(
                        tag: 'story_cover_${story.id}',
                        child: Container(
                          constraints: const BoxConstraints(
                            maxWidth: 290,
                            maxHeight: 290,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.55),
                                blurRadius: 28,
                                offset: const Offset(0, 14),
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: AspectRatio(
                                  aspectRatio: 1.0,
                                  child: CachedNetworkImage(
                                    imageUrl: story.coverImageUrl,
                                    memCacheWidth: 800,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      color: AppColors.surfaceLight,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.warmGold,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      color: AppColors.surfaceLight,
                                      child: const Icon(
                                        Icons.auto_stories_rounded,
                                        color: AppColors.lavender,
                                        size: 64,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (story.isVideo)
                                Positioned(
                                  bottom: 12,
                                  child: GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      _audioService.pause();
                                      setState(() {
                                        _audioOnly = false;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 7,),
                                      decoration: BoxDecoration(
                                        color: const Color(0xEE130E2E),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: AppColors.warmGold, width: 1.2,),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black54,
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.videocam_rounded,
                                              color: AppColors.warmGold, size: 16,),
                                          SizedBox(width: 6),
                                          Text(
                                            'Watch Barbara Video',
                                            style: TextStyle(
                                              color: AppColors.warmGold,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Sleep Timer Remaining Badge ──
                ValueListenableBuilder<Duration?>(
                  valueListenable: _audioService.sleepTimerRemaining,
                  builder: (_, remaining, __) {
                    if (remaining == null) return const SizedBox.shrink();
                    final mins = remaining.inMinutes;
                    final secs = remaining.inSeconds % 60;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warmGold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.warmGold.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bedtime_rounded,
                            color: AppColors.warmGold,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.warmGold,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // ── Story Info & Active Playlist Indicator ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Active Playlist Interactive Badge & Queue Preview
                      ValueListenableBuilder<Playlist?>(
                        valueListenable: _audioService.currentPlaylist,
                        builder: (_, playlist, __) {
                          if (playlist == null) return const SizedBox.shrink();
                          return ValueListenableBuilder<int>(
                            valueListenable:
                                _audioService.currentQueueIndexNotifier,
                            builder: (_, qIndex, __) {
                              final total = _audioService
                                  .playlistQueueNotifier.value.length;
                              final countText =
                                  total > 0 ? ' • ${qIndex + 1} of $total' : '';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: _showPlaylistQueueSheet,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF261D52)
                                          .withValues(alpha: 0.65),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.warmGold
                                            .withValues(alpha: 0.35),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.queue_music_rounded,
                                          color: AppColors.warmGold,
                                          size: 15,
                                        ),
                                        const SizedBox(width: 7),
                                        Flexible(
                                          child: Text(
                                            '${playlist.title}$countText',
                                            style: AppTypography.labelSmall
                                                .copyWith(
                                              color: AppColors.moonlightWhite,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.1,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: AppColors.lavender,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      Text(
                        story.title,
                        style: AppTypography.playerTitle,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Narrated by ${story.narrator}',
                        style: AppTypography.playerSubtitle,
                      ),
                      if (story.description.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          story.description,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.lavender.withValues(alpha: 0.8),
                            height: 1.45,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Frosted Glass Control Panel ──
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 42),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight.withValues(alpha: 0.7),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ── Progress Bar ──
                            StreamBuilder<PositionData>(
                              stream: _audioService.positionDataStream,
                              builder: (context, snapshot) {
                                final positionData = snapshot.data;
                                return ProgressBar(
                                  progress: positionData?.position ?? Duration.zero,
                                  buffered: positionData?.bufferedPosition ?? Duration.zero,
                                  total: positionData?.duration ?? Duration.zero,
                                  progressBarColor: AppColors.warmGold,
                                  baseBarColor: AppColors.lavender.withValues(alpha: 0.3),
                                  bufferedBarColor: AppColors.lavender.withValues(alpha: 0.5),
                                  thumbColor: AppColors.warmGold,
                                  timeLabelTextStyle: AppTypography.labelMedium.copyWith(
                                    color: AppColors.moonlightWhite,
                                  ),
                                  onSeek: _audioService.seek,
                                );
                              },
                            ),

                            const SizedBox(height: 12),

                            // ── Secondary Controls Row (Repeat & Sleep Timer) ──
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Repeat Toggle
                                  ValueListenableBuilder<BedtimeRepeatMode>(
                                    valueListenable: _audioService.repeatMode,
                                    builder: (_, mode, __) {
                                      final isOff =
                                          mode == BedtimeRepeatMode.off;
                                      final isOne =
                                          mode == BedtimeRepeatMode.one;
                                      return IconButton(
                                        icon: Icon(
                                          isOne
                                              ? Icons.repeat_one_rounded
                                              : Icons.repeat_rounded,
                                          color: isOff
                                              ? AppColors.textSecondary
                                              : AppColors.warmGold,
                                          size: 22,
                                        ),
                                        tooltip: isOff
                                            ? 'Repeat Off'
                                            : mode == BedtimeRepeatMode.all
                                                ? 'Repeat All'
                                                : 'Repeat One',
                                        onPressed: () {
                                          HapticFeedback.lightImpact();
                                          _audioService.toggleRepeatMode();
                                        },
                                      );
                                    },
                                  ),

                                  // Sleep Timer Toggle
                                  ValueListenableBuilder<int?>(
                                    valueListenable: _audioService.sleepTimerMinutes,
                                    builder: (_, timerValue, __) {
                                      return IconButton(
                                        icon: Icon(
                                          Icons.bedtime_rounded,
                                          color: timerValue != null
                                              ? AppColors.warmGold
                                              : AppColors.textSecondary,
                                          size: 22,
                                        ),
                                        tooltip: 'Sleep Timer',
                                        onPressed: _showSleepTimerSheet,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 4),

                            // ── Primary Playback Row: Prev | 15s | Play/Pause | 30s | Next ──
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Previous Story in Playlist Button
                                ValueListenableBuilder<int>(
                                  valueListenable:
                                      _audioService.currentQueueIndexNotifier,
                                  builder: (context, _, __) {
                                    return IconButton(
                                      icon: const Icon(
                                        Icons.skip_previous_rounded,
                                        color: AppColors.textPrimary,
                                        size: 34,
                                      ),
                                      tooltip: 'Previous Story',
                                      onPressed: () {
                                        HapticFeedback.mediumImpact();
                                        _audioService.playPrevious();
                                      },
                                    );
                                  },
                                ),

                                // Rewind 15s
                                IconButton(
                                  icon: const Icon(
                                    Icons.replay_10_rounded,
                                    color: AppColors.textPrimary,
                                    size: 30,
                                  ),
                                  tooltip: 'Rewind 15s',
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    final pos = _audioService.player.position;
                                    _audioService.seek(pos - const Duration(seconds: 15));
                                  },
                                ),

                                // Play/Pause Button with Error & Cancel Handling
                                ValueListenableBuilder<String?>(
                                  valueListenable: _audioService.playbackError,
                                  builder: (context, playbackError, _) {
                                    return StreamBuilder<PlayerState>(
                                      stream: _audioService.player.playerStateStream,
                                      builder: (context, snapshot) {
                                        final playerState = snapshot.data;
                                        final processingState = playerState?.processingState;
                                        final playing = playerState?.playing;

                                        return _PlayPauseButton(
                                          errorMessage: playbackError,
                                          isLoading: (processingState == ProcessingState.loading ||
                                                  processingState == ProcessingState.buffering) &&
                                              playbackError == null,
                                          isPlaying: playing == true,
                                          isCompleted: processingState == ProcessingState.completed,
                                          onPlay: () {
                                            HapticFeedback.mediumImpact();
                                            _audioService.play();
                                          },
                                          onPause: () {
                                            HapticFeedback.mediumImpact();
                                            _audioService.pause();
                                          },
                                          onReplay: () {
                                            HapticFeedback.mediumImpact();
                                            _audioService.seek(Duration.zero);
                                          },
                                          onCancel: () {
                                            HapticFeedback.selectionClick();
                                            _audioService.cancelLoading();
                                          },
                                          onRetry: () {
                                            HapticFeedback.mediumImpact();
                                            if (_story != null) {
                                              _audioService.playStory(_story!);
                                            }
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),

                                // Forward 30s
                                IconButton(
                                  icon: const Icon(
                                    Icons.forward_30_rounded,
                                    color: AppColors.textPrimary,
                                    size: 30,
                                  ),
                                  tooltip: 'Forward 30s',
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    final pos = _audioService.player.position;
                                    _audioService.seek(pos + const Duration(seconds: 30));
                                  },
                                ),

                                // Next Story in Playlist Button
                                ValueListenableBuilder<int>(
                                  valueListenable:
                                      _audioService.currentQueueIndexNotifier,
                                  builder: (context, _, __) {
                                    return IconButton(
                                      icon: const Icon(
                                        Icons.skip_next_rounded,
                                        color: AppColors.textPrimary,
                                        size: 34,
                                      ),
                                      tooltip: 'Next Story',
                                      onPressed: () {
                                        HapticFeedback.mediumImpact();
                                        _audioService.skipToNext();
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Wind Down Ambient Stars Animation ──
class _WindDownStars extends StatefulWidget {
  const _WindDownStars();

  @override
  State<_WindDownStars> createState() => _WindDownStarsState();
}

class _WindDownStarsState extends State<_WindDownStars> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_PlayerStar> _stars;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    final random = Random(88);
    _stars = List.generate(24, (_) {
      return _PlayerStar(
        x: random.nextDouble(),
        y: random.nextDouble() * 0.7, // top 70% of screen
        size: random.nextDouble() * 2.0 + 0.8,
        opacity: random.nextDouble() * 0.5 + 0.15,
        phase: random.nextDouble(),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return RepaintBoundary(
          child: CustomPaint(
            painter: _PlayerStarPainter(
              stars: _stars,
              animValue: _controller.value,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class _PlayerStar {
  final double x;
  final double y;
  final double size;
  final double opacity;
  final double phase;

  _PlayerStar({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.phase,
  });
}

class _PlayerStarPainter extends CustomPainter {
  final List<_PlayerStar> stars;
  final double animValue;

  _PlayerStarPainter({required this.stars, required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in stars) {
      final twinkle = (sin((animValue + star.phase) * pi * 2) + 1) / 2;
      final opacity = star.opacity * (0.2 + twinkle * 0.8);
      final paint = Paint()
        ..color = AppColors.warmGold.withValues(alpha: opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, star.size * 0.6);
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_PlayerStarPainter old) => old.animValue != animValue;
}

// ── Extracted Play/Pause Button ──
class _PlayPauseButton extends StatelessWidget {
  final bool isLoading;
  final bool isPlaying;
  final bool isCompleted;
  final String? errorMessage;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onReplay;
  final VoidCallback onCancel;
  final VoidCallback onRetry;

  const _PlayPauseButton({
    required this.isLoading,
    required this.isPlaying,
    required this.isCompleted,
    this.errorMessage,
    required this.onPlay,
    required this.onPause,
    required this.onReplay,
    required this.onCancel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return GestureDetector(
        onTap: onRetry,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.warmGold,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.warmGold.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: AppColors.deepNavy,
                size: 44,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warmGold.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'Tap to retry',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.warmGold,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (isLoading) {
      return GestureDetector(
        onTap: onCancel,
        child: Container(
          width: 80,
          height: 80,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.warmGold.withValues(alpha: 0.85),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.warmGold.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  color: AppColors.deepNavy,
                  strokeWidth: 3.5,
                ),
              ),
              Icon(
                Icons.close_rounded,
                color: AppColors.deepNavy,
                size: 24,
              ),
            ],
          ),
        ),
      );
    }

    final IconData icon;
    final VoidCallback onTap;

    if (isCompleted) {
      icon = Icons.replay_rounded;
      onTap = onReplay;
    } else if (isPlaying) {
      icon = Icons.pause_rounded;
      onTap = onPause;
    } else {
      icon = Icons.play_arrow_rounded;
      onTap = onPlay;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: AppColors.warmGold,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.deepNavy, size: 48),
      ),
    );
  }
}

// ── Frosted Glass Action Button for Top App Bar ──
class _PlayerGlassButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool isActive;

  const _PlayerGlassButton({
    required this.icon,
    this.onTap,
    this.tooltip,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap != null
          ? () {
              HapticFeedback.selectionClick();
              onTap!();
            }
          : null,
      child: Container(
        width: 44,
        height: 44,
        padding: const EdgeInsets.all(2),
        alignment: Alignment.center,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? AppColors.warmGold.withValues(alpha: 0.25)
                : AppColors.surfaceLight.withValues(alpha: 0.65),
            border: Border.all(
              color: isActive
                  ? AppColors.warmGold
                  : Colors.white.withValues(alpha: 0.2),
              width: 1.2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.warmGold.withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: icon,
        ),
      ),
    );
  }
}
