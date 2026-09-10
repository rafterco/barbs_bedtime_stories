import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import 'package:barbs_bedtime_stories/core/theme/app_colors.dart';
import 'package:barbs_bedtime_stories/core/theme/app_typography.dart';
import 'package:barbs_bedtime_stories/data/models/story.dart';
import 'package:barbs_bedtime_stories/services/audio_player_service.dart';

/// A card widget for displaying a story in a horizontal or vertical list.
/// Shows cover art, title, narrator, and duration with a play indicator.
class StoryCard extends StatelessWidget {
  final Story story;
  final bool compact;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final VoidCallback? onTap;

  const StoryCard({
    super.key,
    required this.story,
    this.compact = false,
    this.margin,
    this.width,
    this.onTap,
  });

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    return '${hours}h ${remaining}m';
  }

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompactCard(context);
    return _buildFullCard(context);
  }

  Widget _buildFullCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (onTap != null) {
          onTap!();
        } else {
          context.push('/story/${story.id}');
        }
      },
      child: Container(
        width: width ?? 148,
        margin: margin ?? const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF221A48),
              Color(0xFF130E2E),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.warmGold.withValues(alpha: 0.2),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E153F).withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cover art
            AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: story.coverImageUrl,
                        memCacheWidth: 600,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Shimmer.fromColors(
                          baseColor: AppColors.surfaceLight,
                          highlightColor: AppColors.cardBackgroundLight,
                          child: Container(color: AppColors.surfaceLight),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.surfaceLight,
                          child: const Icon(
                            Icons.auto_stories,
                            color: AppColors.textMuted,
                            size: 40,
                          ),
                        ),
                      ),
                      // Subtle bottom gradient overlay for play button contrast
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 50,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.55),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Duration badge (top-right for a clean, open artwork)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6.5,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            _formatDuration(story.duration),
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                      // Video story badge
                      if (story.isVideo)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.warmGold.withValues(alpha: 0.6),
                                width: 0.8,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.videocam_rounded,
                                  color: AppColors.warmGold,
                                  size: 11,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'VIDEO',
                                  style: TextStyle(
                                    color: AppColors.warmGold,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Play/Equalizer button overlay
                      Positioned(
                        bottom: 6,
                        left: 6,
                        child: ValueListenableBuilder<Story?>(
                          valueListenable: AudioPlayerService.instance.currentStory,
                          builder: (_, currentStory, __) {
                            final isCurrent = currentStory?.id == story.id;
                            return ValueListenableBuilder<bool>(
                              valueListenable: AudioPlayerService.instance.isPlaying,
                              builder: (_, isPlaying, __) {
                                final isCurrentPlaying = isCurrent && isPlaying;
                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    if (story.isVideo) {
                                      AudioPlayerService.instance.pause();
                                      context.push('/story/${story.id}');
                                    } else if (isCurrent) {
                                      AudioPlayerService.instance.togglePlayPause();
                                    } else {
                                      AudioPlayerService.instance.playStory(story);
                                    }
                                  },
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: AppColors.warmGold,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.warmGold.withValues(
                                            alpha: isCurrentPlaying ? 0.6 : 0.3,
                                          ),
                                          blurRadius: isCurrentPlaying ? 10 : 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      isCurrentPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: AppColors.deepNavy,
                                      size: 18,
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
              ),
            ),
            const SizedBox(height: 8),
            // Title (2 lines max, uniform height so all cards align)
            SizedBox(
              height: 36,
              child: Text(
                story.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.headlineSmall.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(height: 2),
            // Narrator
            Text(
              story.narrator,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 11,
                color: AppColors.lavender.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (onTap != null) {
          onTap!();
        } else {
          context.push('/story/${story.id}');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF261D52),
              Color(0xFF151034),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.warmGold.withValues(alpha: 0.28),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF261D52).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Cover thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: story.coverImageUrl,
                width: 54,
                height: 54,
                memCacheWidth: 160,
                fit: BoxFit.cover,
                placeholder: (_, __) => Shimmer.fromColors(
                  baseColor: AppColors.surfaceLight,
                  highlightColor: AppColors.cardBackgroundLight,
                  child: Container(
                    width: 54,
                    height: 54,
                    color: AppColors.surfaceLight,
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 54,
                  height: 54,
                  color: AppColors.surfaceLight,
                  child: const Icon(
                    Icons.auto_stories,
                    color: AppColors.textMuted,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headlineSmall.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (story.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      story.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        '${story.narrator} · ${_formatDuration(story.duration)}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.lavender.withValues(alpha: 0.75),
                          fontSize: 11.5,
                        ),
                      ),
                      if (story.isVideo) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.warmGold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppColors.warmGold.withValues(alpha: 0.4),
                              width: 0.8,
                            ),
                          ),
                          child: const Text(
                            'VIDEO',
                            style: TextStyle(
                              color: AppColors.warmGold,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Play button
            ValueListenableBuilder<Story?>(
              valueListenable: AudioPlayerService.instance.currentStory,
              builder: (_, currentStory, __) {
                final isCurrent = currentStory?.id == story.id;
                return ValueListenableBuilder<bool>(
                  valueListenable: AudioPlayerService.instance.isPlaying,
                  builder: (_, isPlaying, __) {
                    final isCurrentPlaying = isCurrent && isPlaying;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        if (story.isVideo) {
                          AudioPlayerService.instance.pause();
                          context.push('/story/${story.id}');
                        } else if (isCurrent) {
                          AudioPlayerService.instance.togglePlayPause();
                        } else {
                          AudioPlayerService.instance.playStory(story);
                        }
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.warmGold,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.warmGold.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isCurrentPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: AppColors.deepNavy,
                          size: 22,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
