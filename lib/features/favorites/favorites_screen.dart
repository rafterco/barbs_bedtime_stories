import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:barbs_bedtime_stories/core/theme/app_colors.dart';
import 'package:barbs_bedtime_stories/core/theme/app_typography.dart';
import 'package:barbs_bedtime_stories/data/models/playlist.dart';
import 'package:barbs_bedtime_stories/data/models/story.dart';
import 'package:barbs_bedtime_stories/data/providers.dart';
import 'package:barbs_bedtime_stories/services/favorites_service.dart';
import 'package:barbs_bedtime_stories/widgets/playlist_card.dart';
import 'package:barbs_bedtime_stories/widgets/story_card.dart';
import 'package:barbs_bedtime_stories/widgets/dreamy_states.dart';
import 'package:barbs_bedtime_stories/widgets/skeleton_loading.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storiesAsync = ref.watch(publishedStoriesProvider);
    final playlistsAsync = ref.watch(publishedPlaylistsProvider);
    final favService = FavoritesService.instance;

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
        title: const Text('Favourites', style: AppTypography.headlineLarge),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
            child: Container(
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  favService.favoriteIds,
                  favService.favoritePlaylistIds,
                ]),
                builder: (context, _) {
                  final storyCount = favService.favoriteIds.value.length;
                  final playlistCount = favService.favoritePlaylistIds.value.length;

                  return TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppColors.warmGold,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.warmGold.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: AppColors.midnightBlack,
                    unselectedLabelColor: AppColors.moonlightWhite,
                    labelStyle: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.auto_stories_rounded, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              storyCount > 0 ? 'Stories ($storyCount)' : 'Stories',
                            ),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.queue_music_rounded, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              playlistCount > 0
                                  ? 'Playlists ($playlistCount)'
                                  : 'Playlists',
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          // ── Stories Tab ──
          _FavoriteStoriesTab(
            storiesAsync: storiesAsync,
            favService: favService,
          ),

          // ── Playlists Tab ──
          _FavoritePlaylistsTab(
            playlistsAsync: playlistsAsync,
            favService: favService,
          ),
        ],
      ),
    );
  }
}

class _FavoriteStoriesTab extends StatelessWidget {
  final AsyncValue<List<Story>> storiesAsync;
  final FavoritesService favService;

  const _FavoriteStoriesTab({
    required this.storiesAsync,
    required this.favService,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: favService.favoriteIds,
      builder: (context, favIds, _) {
        return storiesAsync.when(
          data: (allStories) {
            final favoriteStories = allStories
                .where((story) => favIds.contains(story.id))
                .toList();

            if (favoriteStories.isEmpty) {
              return DreamyEmptyWidget(
                emoji: '🌙',
                title: 'No favourite stories yet',
                subtitle:
                    'Tap the heart icon on any bedtime story to save it here for quick access.',
                actionLabel: 'Browse Stories',
                onAction: () {
                  HapticFeedback.lightImpact();
                  context.go('/browse');
                },
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              physics: const BouncingScrollPhysics(),
              itemCount: favoriteStories.length,
              itemBuilder: (context, index) {
                final story = favoriteStories[index];
                return Dismissible(
                  key: Key('fav_story_${story.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.favorite_border_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  onDismissed: (_) {
                    HapticFeedback.mediumImpact();
                    favService.removeFavorite(story.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${story.title} removed from favourites'),
                        backgroundColor: AppColors.surfaceLight,
                      ),
                    );
                  },
                  child: StoryCard(
                    story: story,
                    compact: true,
                  ),
                );
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: BrowseGridSkeleton(),
          ),
          error: (_, __) => DreamyErrorWidget(
            message: 'Could not load favorite stories',
            onRetry: () => favService.init(),
          ),
        );
      },
    );
  }
}

class _FavoritePlaylistsTab extends StatelessWidget {
  final AsyncValue<List<Playlist>> playlistsAsync;
  final FavoritesService favService;

  const _FavoritePlaylistsTab({
    required this.playlistsAsync,
    required this.favService,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: favService.favoritePlaylistIds,
      builder: (context, favPlaylistIds, _) {
        return playlistsAsync.when(
          data: (allPlaylists) {
            final favoritePlaylists = allPlaylists
                .where((playlist) => favPlaylistIds.contains(playlist.id))
                .toList();

            if (favoritePlaylists.isEmpty) {
              return DreamyEmptyWidget(
                emoji: '✨',
                title: 'No favourite playlists yet',
                subtitle:
                    'Tap the heart icon on any bedtime playlist to keep your collections together.',
                actionLabel: 'Browse Playlists',
                onAction: () {
                  HapticFeedback.lightImpact();
                  context.go('/browse');
                },
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              physics: const BouncingScrollPhysics(),
              itemCount: favoritePlaylists.length,
              itemBuilder: (context, index) {
                final playlist = favoritePlaylists[index];
                return Dismissible(
                  key: Key('fav_playlist_${playlist.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.favorite_border_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  onDismissed: (_) {
                    HapticFeedback.mediumImpact();
                    favService.removePlaylistFavorite(playlist.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${playlist.title} removed from favourites'),
                        backgroundColor: AppColors.surfaceLight,
                      ),
                    );
                  },
                  child: PlaylistCard(
                    playlist: playlist,
                  ),
                );
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: BrowseGridSkeleton(),
          ),
          error: (_, __) => DreamyErrorWidget(
            message: 'Could not load favorite playlists',
            onRetry: () => favService.init(),
          ),
        );
      },
    );
  }
}
