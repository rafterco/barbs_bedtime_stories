import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import 'package:barbs_bedtime_stories/core/theme/app_colors.dart';
import 'package:barbs_bedtime_stories/core/theme/app_typography.dart';
import 'package:barbs_bedtime_stories/data/models/playlist.dart';
import 'package:barbs_bedtime_stories/services/favorites_service.dart';

/// A card widget for displaying a playlist with cover art, story count, and 1-tap favorite toggle.
class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final bool showFavoriteButton;

  const PlaylistCard({
    super.key,
    required this.playlist,
    this.showFavoriteButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/playlist/${playlist.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.warmGold.withValues(alpha: 0.28),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF261D52).withValues(alpha: 0.4),
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
        child: Row(
          children: [
            // Cover art with playlist badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: playlist.coverImageUrl,
                    width: 76,
                    height: 76,
                    memCacheWidth: 220,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Shimmer.fromColors(
                      baseColor: AppColors.surfaceLight,
                      highlightColor: AppColors.cardBackgroundLight,
                      child: Container(
                        width: 76,
                        height: 76,
                        color: AppColors.surfaceLight,
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 76,
                      height: 76,
                      color: AppColors.surfaceLight,
                      child: const Icon(
                        Icons.queue_music_rounded,
                        color: AppColors.lavender,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                // Stacked playlist overlay icon
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.collections_bookmark_rounded,
                      color: AppColors.warmGold,
                      size: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lavender.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          'PLAYLIST',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.lavender,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${playlist.storyIds.length} ${playlist.storyIds.length == 1 ? "story" : "stories"}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.lavender.withValues(alpha: 0.8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    playlist.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headlineMedium.copyWith(fontSize: 16),
                  ),
                  if (playlist.description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      playlist.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Favorite Button
            if (showFavoriteButton)
              ValueListenableBuilder<Set<String>>(
                valueListenable: FavoritesService.instance.favoritePlaylistIds,
                builder: (context, favPlaylists, _) {
                  final isFav = favPlaylists.contains(playlist.id);
                  return IconButton(
                    icon: Icon(
                      isFav
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFav
                          ? AppColors.warmGold
                          : AppColors.textSecondary.withValues(alpha: 0.6),
                      size: 22,
                    ),
                    tooltip: isFav ? 'In Favourites' : 'Add to Favourites',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      FavoritesService.instance.togglePlaylistFavorite(playlist.id);
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            !isFav
                                ? '❤️ Added playlist "${playlist.title}" to Favourites'
                                : 'Removed "${playlist.title}" from Favourites',
                            style: const TextStyle(color: Colors.white),
                          ),
                          duration: const Duration(seconds: 2),
                          backgroundColor: AppColors.surfaceLight,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                  );
                },
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
