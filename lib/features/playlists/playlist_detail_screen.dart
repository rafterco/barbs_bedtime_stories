import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import 'package:barbs_bedtime_stories/core/theme/app_colors.dart';
import 'package:barbs_bedtime_stories/core/theme/app_typography.dart';
import 'package:barbs_bedtime_stories/data/models/playlist.dart';
import 'package:barbs_bedtime_stories/data/models/story.dart';
import 'package:barbs_bedtime_stories/data/providers.dart';
import 'package:barbs_bedtime_stories/services/audio_player_service.dart';
import 'package:barbs_bedtime_stories/services/favorites_service.dart';
import 'package:barbs_bedtime_stories/widgets/story_card.dart';

/// Detail screen for a playlist, showing its stories in a scrollable list.
class PlaylistDetailScreen extends ConsumerWidget {
  final String playlistId;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(publishedPlaylistsProvider);

    return playlistsAsync.when(
      data: (playlists) {
        final playlist = playlists.where((p) => p.id == playlistId).firstOrNull;
        if (playlist == null) {
          return Scaffold(
            backgroundColor: AppColors.deepNavy,
            appBar: AppBar(),
            body: const Center(
              child: Text(
                'Playlist not found',
                style: AppTypography.bodyLarge,
              ),
            ),
          );
        }
        return _PlaylistDetailContent(playlist: playlist);
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.deepNavy,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        backgroundColor: AppColors.deepNavy,
        appBar: AppBar(),
        body: Center(
          child: Text(
            'Something went wrong',
            style: AppTypography.bodyLarge.copyWith(color: AppColors.error),
          ),
        ),
      ),
    );
  }
}

class _PlaylistDetailContent extends ConsumerWidget {
  final Playlist playlist;

  const _PlaylistDetailContent({required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(publishedStoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Collapsing header with cover art ──
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.deepNavy,
            actions: [
              ValueListenableBuilder<Set<String>>(
                valueListenable: FavoritesService.instance.favoritePlaylistIds,
                builder: (context, favPlaylists, _) {
                  final isFav = favPlaylists.contains(playlist.id);
                  return IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFav ? AppColors.warmGold : AppColors.textPrimary,
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
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: playlist.coverImageUrl,
                    memCacheWidth: 800,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: AppColors.surfaceLight,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.surfaceLight,
                      child: const Icon(
                        Icons.queue_music_rounded,
                        color: AppColors.lavender,
                        size: 64,
                      ),
                    ),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.deepNavy.withValues(alpha: 0.6),
                          AppColors.deepNavy,
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                  // Playlist info
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lavender.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${playlist.storyIds.length} STORIES',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.lavender,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          playlist.title,
                          style: AppTypography.displaySmall,
                        ),
                        if (playlist.description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            playlist.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.lavender,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Story list & Play All ──
          storiesAsync.when(
            data: (List<Story> allStories) {
              final Map<String, Story> storyMap = {};
              for (final s in allStories) {
                storyMap[s.id] = s;
                storyMap[s.title.trim().toLowerCase()] = s;
              }
              final List<Story> playlistStories = [];
              for (final identifier in playlist.storyIds) {
                final match = storyMap[identifier] ?? storyMap[identifier.trim().toLowerCase()];
                if (match != null && !playlistStories.any((Story existing) => existing.id == match.id)) {
                  playlistStories.add(match);
                }
              }

              if (playlistStories.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text(
                        'No stories in this playlist yet',
                        style: AppTypography.bodyMedium,
                      ),
                    ),
                  ),
                );
              }

              return SliverMainAxisGroup(
                slivers: [
                  // ── Play All button ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          AudioPlayerService.instance.playPlaylist(
                            playlistStories,
                            playlist: playlist,
                          );
                          context.push('/story/${playlistStories.first.id}');
                        },
                        icon: const Icon(Icons.play_arrow_rounded, size: 28),
                        label: Text('Play All (${playlistStories.length} Stories)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warmGold,
                          foregroundColor: AppColors.deepNavy,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                          minimumSize: const Size.fromHeight(50),
                        ),
                      ),
                    ),
                  ),
                  // ── Story list ──
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => StoryCard(
                          story: playlistStories[i],
                          compact: true,
                          onTap: () {
                            AudioPlayerService.instance.playPlaylist(
                              playlistStories,
                              startIndex: i,
                              playlist: playlist,
                            );
                            context.push('/story/${playlistStories[i].id}');
                          },
                        ),
                        childCount: playlistStories.length,
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => SliverToBoxAdapter(
              child: Column(
                children: List.generate(
                  4,
                  (_) => Shimmer.fromColors(
                    baseColor: AppColors.surfaceLight,
                    highlightColor: AppColors.cardBackgroundLight,
                    child: Container(
                      height: 72,
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            error: (_, __) => const SliverToBoxAdapter(
              child: SizedBox.shrink(),
            ),
          ),

          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}
