import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:barbs_bedtime_stories/core/theme/app_colors.dart';
import 'package:barbs_bedtime_stories/core/theme/app_typography.dart';
import 'package:barbs_bedtime_stories/data/models/story.dart';
import 'package:barbs_bedtime_stories/services/audio_player_service.dart';

/// A prominent mini-player that appears above the bottom nav when audio is playing.
/// Tapping it opens the full player screen.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final service = AudioPlayerService.instance;
    return ValueListenableBuilder<bool>(
      valueListenable: service.isVideoPlayerFullScreen,
      builder: (_, isVideoFullScreen, __) {
        if (isVideoFullScreen) return const SizedBox.shrink();
        return ValueListenableBuilder<Story?>(
          valueListenable: service.currentStory,
          builder: (_, story, __) {
            if (story == null) return const SizedBox.shrink();
            return _MiniPlayerBar(story: story);
          },
        );
      },
    );
  }
}

class _MiniPlayerBar extends StatelessWidget {
  final Story story;

  const _MiniPlayerBar({required this.story});

  @override
  Widget build(BuildContext context) {
    final service = AudioPlayerService.instance;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/story/${story.id}');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF261D52),
              Color(0xFF130E2E),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.warmGold.withValues(alpha: 0.45),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepViolet.withValues(alpha: 0.5),
              blurRadius: 16,
              offset: const Offset(0, -3),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Track Info & Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 8, 6),
              child: Row(
                children: [
                  // Cover art with gold glow
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.warmGold.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: story.coverImageUrl,
                            width: 44,
                            height: 44,
                            memCacheWidth: 140,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.cardBackground,
                              child: const Icon(
                                Icons.auto_stories,
                                color: AppColors.warmGold,
                                size: 22,
                              ),
                            ),
                          ),
                          if (story.isVideo)
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.videocam_rounded,
                                  color: AppColors.warmGold,
                                  size: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Title & Narrator with generous width
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          story.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelLarge.copyWith(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.moonlightWhite,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 1.5),
                        ValueListenableBuilder(
                          valueListenable: service.currentPlaylist,
                          builder: (_, playlist, __) {
                            final subtitle = story.isVideo
                                ? 'Video Story • ${story.narrator}'
                                : (playlist != null
                                    ? '${playlist.title} • ${story.narrator}'
                                    : story.narrator);
                            return Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 11,
                                color: AppColors.lavender,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Play/Pause button
                  ValueListenableBuilder<bool>(
                    valueListenable: service.isPlaying,
                    builder: (_, isPlaying, __) {
                      return Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.warmGold,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.warmGold.withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: AppColors.midnightBlack,
                            size: 22,
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            service.togglePlayPause();
                          },
                          padding: EdgeInsets.zero,
                        ),
                      );
                    },
                  ),
                  // Skip Next Button (only for audio stories / playlists)
                  if (!story.isVideo) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(
                        Icons.skip_next_rounded,
                        color: AppColors.moonlightWhite,
                        size: 22,
                      ),
                      tooltip: 'Next Story',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        service.skipToNext();
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                    ),
                  ],
                  const SizedBox(width: 2),
                  // Close button
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textMuted,
                      size: 19,
                    ),
                    tooltip: 'Close Player',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      service.stopPlayback();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 26,
                      minHeight: 26,
                    ),
                  ),
                ],
              ),
            ),
            // Bottom Progress Bar (inset to flat section)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: StreamBuilder<PositionData>(
                stream: service.positionDataStream,
                builder: (_, snapshot) {
                  final data = snapshot.data;
                  final progress = data != null && data.duration.inMilliseconds > 0
                      ? data.position.inMilliseconds / data.duration.inMilliseconds
                      : 0.0;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      color: AppColors.warmGold,
                      minHeight: 2.5,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
