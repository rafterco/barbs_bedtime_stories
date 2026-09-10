import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import 'package:barbs_bedtime_stories/core/theme/app_colors.dart';
import 'package:barbs_bedtime_stories/core/theme/app_typography.dart';
import 'package:barbs_bedtime_stories/data/models/story.dart';
import 'package:barbs_bedtime_stories/services/audio_player_service.dart';

/// A "Continue Listening" banner that shows the last partially-played story.
/// Appears at the top of the home screen when there's an active story with progress.
class ContinueListeningBanner extends StatelessWidget {
  const ContinueListeningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final service = AudioPlayerService.instance;
    return ValueListenableBuilder<Story?>(
      valueListenable: service.currentStory,
      builder: (_, story, __) {
        if (story == null) return const SizedBox.shrink();
        return ValueListenableBuilder<bool>(
          valueListenable: service.isPlaying,
          builder: (_, isPlaying, __) {
            // When actively playing, the elevated MiniPlayer shows live status at the bottom
            if (isPlaying) return const SizedBox.shrink();
            return _BannerContent(story: story);
          },
        );
      },
    );
  }
}

class _BannerContent extends StatelessWidget {
  final Story story;

  const _BannerContent({required this.story});

  @override
  Widget build(BuildContext context) {
    final service = AudioPlayerService.instance;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/story/${story.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF28205C),
              Color(0xFF161238),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.warmGold.withValues(alpha: 0.25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.warmGold,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'CONTINUE LISTENING',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.warmGold,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Story info + play button
            Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: story.coverImageUrl,
                    width: 46,
                    height: 46,
                    memCacheWidth: 140,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Shimmer.fromColors(
                      baseColor: AppColors.surfaceLight,
                      highlightColor: AppColors.cardBackgroundLight,
                      child: Container(width: 46, height: 46, color: AppColors.surfaceLight),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 46,
                      height: 46,
                      color: AppColors.surfaceLight,
                      child: const Icon(Icons.nightlight_round, color: AppColors.warmGold, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.headlineSmall.copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Narrated by ${story.narrator}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.lavender,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.warmGold,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.warmGold.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.deepNavy,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Progress bar
            StreamBuilder<PositionData>(
              stream: service.positionDataStream,
              builder: (_, snapshot) {
                final data = snapshot.data;
                final progress = data != null &&
                        data.duration.inMilliseconds > 0
                    ? data.position.inMilliseconds /
                        data.duration.inMilliseconds
                    : 0.0;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: AppColors.surfaceLight,
                    color: AppColors.warmGold,
                    minHeight: 3,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
