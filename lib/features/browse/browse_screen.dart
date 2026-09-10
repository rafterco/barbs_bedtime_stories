import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barbs_bedtime_stories/core/theme/app_colors.dart';
import 'package:barbs_bedtime_stories/core/theme/app_typography.dart';
import 'package:barbs_bedtime_stories/data/models/playlist.dart';
import 'package:barbs_bedtime_stories/data/models/story.dart';
import 'package:barbs_bedtime_stories/data/providers.dart';
import 'package:barbs_bedtime_stories/widgets/story_card.dart';
import 'package:barbs_bedtime_stories/widgets/playlist_card.dart';
import 'package:barbs_bedtime_stories/widgets/skeleton_loading.dart';
import 'package:barbs_bedtime_stories/widgets/dreamy_states.dart';

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _storySearchController = TextEditingController();
  final TextEditingController _playlistSearchController = TextEditingController();
  String _storySearchQuery = '';
  String _playlistSearchQuery = '';
  String _selectedCategoryId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    _storySearchController.addListener(() {
      setState(() {
        _storySearchQuery = _storySearchController.text.toLowerCase();
      });
    });

    _playlistSearchController.addListener(() {
      setState(() {
        _playlistSearchQuery = _playlistSearchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _storySearchController.dispose();
    _playlistSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final storiesAsync = ref.watch(publishedStoriesProvider);
    final playlistsAsync = ref.watch(publishedPlaylistsProvider);

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
        title: const Text('Browse Library', style: AppTypography.headlineLarge),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
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
              child: TabBar(
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
                        storiesAsync.when(
                          data: (stories) => Text(
                            'Stories (${stories.where((s) => !s.isVideo).length})',
                          ),
                          loading: () => const Text('Stories'),
                          error: (_, __) => const Text('Stories'),
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
                        playlistsAsync.when(
                          data: (playlists) =>
                              Text('Playlists (${playlists.length})'),
                          loading: () => const Text('Playlists'),
                          error: (_, __) => const Text('Playlists'),
                        ),
                      ],
                    ),
                  ),
                ],
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
          _buildStoriesTab(categoriesAsync, storiesAsync),

          // ── Playlists Tab ──
          _buildPlaylistsTab(playlistsAsync),
        ],
      ),
    );
  }

  Widget _buildStoriesTab(
    AsyncValue<dynamic> categoriesAsync,
    AsyncValue<List<Story>> storiesAsync,
  ) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: TextField(
            controller: _storySearchController,
            style: AppTypography.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Search bedtime stories...',
              hintStyle:
                  AppTypography.bodyLarge.copyWith(color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.search, color: AppColors.lavender),
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),

        // Categories
        categoriesAsync.when(
          data: (categories) {
            if (categories.isEmpty) return const SizedBox.shrink();
            return SizedBox(
              height: 46,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                itemCount: categories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildCategoryChip('All Stories', '');
                  }
                  final category = categories[index - 1];
                  return _buildCategoryChip(
                    '${category.icon} ${category.name}',
                    category.id,
                  );
                },
              ),
            );
          },
          loading: () => const SizedBox(
            height: 46,
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.lavender,
                strokeWidth: 2,
              ),
            ),
          ),
          error: (_, __) => const SizedBox(height: 46),
        ),

        const SizedBox(height: 8),

        // Stories Grid
        Expanded(
          child: RefreshIndicator(
            color: AppColors.warmGold,
            backgroundColor: AppColors.surfaceLight,
            onRefresh: () async {
              ref.invalidate(publishedStoriesProvider);
              ref.invalidate(categoriesProvider);
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: storiesAsync.when(
              data: (stories) {
                final filtered = stories.where((s) {
                  if (s.isVideo) return false;
                  final matchesSearch = s.title
                          .toLowerCase()
                          .contains(_storySearchQuery) ||
                      s.tags.any(
                          (t) => t.toLowerCase().contains(_storySearchQuery),
                      );
                  final matchesCategory = _selectedCategoryId.isEmpty ||
                      s.category == _selectedCategoryId;
                  return matchesSearch && matchesCategory;
                }).toList();

                if (filtered.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    children: const [
                      SizedBox(height: 80),
                      DreamyEmptyWidget(
                        emoji: '🔍',
                        title: 'No stories found',
                        subtitle: 'Try a different search keyword or category',
                      ),
                    ],
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return StoryCard(
                      story: filtered[index],
                      width: double.infinity,
                      margin: EdgeInsets.zero,
                    );
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: BrowseGridSkeleton(),
              ),
              error: (error, _) => ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: [
                  const SizedBox(height: 80),
                  DreamyErrorWidget(
                    message: 'Could not load stories right now',
                    onRetry: () => ref.invalidate(publishedStoriesProvider),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaylistsTab(AsyncValue<List<Playlist>> playlistsAsync) {
    return Column(
      children: [
        // Playlist Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: TextField(
            controller: _playlistSearchController,
            style: AppTypography.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Search bedtime playlists...',
              hintStyle:
                  AppTypography.bodyLarge.copyWith(color: AppColors.textMuted),
              prefixIcon: const Icon(
                Icons.queue_music_rounded,
                color: AppColors.lavender,
              ),
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),

        // Playlists List
        Expanded(
          child: RefreshIndicator(
            color: AppColors.warmGold,
            backgroundColor: AppColors.surfaceLight,
            onRefresh: () async {
              ref.invalidate(publishedPlaylistsProvider);
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: playlistsAsync.when(
              data: (playlists) {
                final filtered = playlists.where((p) {
                  return p.title
                          .toLowerCase()
                          .contains(_playlistSearchQuery) ||
                      p.description
                          .toLowerCase()
                          .contains(_playlistSearchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    children: const [
                      SizedBox(height: 80),
                      DreamyEmptyWidget(
                        emoji: '📚',
                        title: 'No playlists found',
                        subtitle: 'Try searching for a different playlist collection',
                      ),
                    ],
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return PlaylistCard(playlist: filtered[index]);
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: BrowseGridSkeleton(),
              ),
              error: (error, _) => ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: [
                  const SizedBox(height: 80),
                  DreamyErrorWidget(
                    message: 'Could not load playlists right now',
                    onRetry: () => ref.invalidate(publishedPlaylistsProvider),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, String id) {
    final isSelected = _selectedCategoryId == id;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedCategoryId = id;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.warmGold : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.warmGold
                : AppColors.lavender.withValues(alpha: 0.2),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: isSelected ? AppColors.deepNavy : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
