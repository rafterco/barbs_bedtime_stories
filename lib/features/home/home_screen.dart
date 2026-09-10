import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shimmer/shimmer.dart';

import 'package:barbs_bedtime_stories/core/theme/app_colors.dart';
import 'package:barbs_bedtime_stories/core/theme/app_typography.dart';
import 'package:barbs_bedtime_stories/data/models/playlist.dart';
import 'package:barbs_bedtime_stories/data/models/story.dart';
import 'package:barbs_bedtime_stories/data/models/app_config.dart';
import 'package:barbs_bedtime_stories/data/providers.dart';
import 'package:barbs_bedtime_stories/services/ambient_sound_service.dart';
import 'package:barbs_bedtime_stories/services/audio_player_service.dart';
import 'package:barbs_bedtime_stories/features/player/widgets/sleep_timer_sheet.dart';
import 'package:barbs_bedtime_stories/features/player/video_story_player_screen.dart';
import 'package:barbs_bedtime_stories/widgets/story_card.dart';
import 'package:barbs_bedtime_stories/widgets/playlist_card.dart';
import 'package:barbs_bedtime_stories/widgets/skeleton_loading.dart';

/// The main home screen with a dreamy bedtime aesthetic.
/// Shows greeting, featured story, trending stories, and playlists.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  List<Color> _getHeaderGradientColors() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      // Morning Dawn
      return [
        const Color(0xFF1E2F5D),
        const Color(0xFF121B3B),
        AppColors.deepNavy,
      ];
    } else if (hour >= 12 && hour < 17) {
      // Afternoon
      return [
        const Color(0xFF222452),
        const Color(0xFF141638),
        AppColors.deepNavy,
      ];
    } else if (hour >= 17 && hour < 21) {
      // Warm Twilight (5 PM - 9 PM) - Soothing violet/indigo twilight
      return [
        const Color(0xFF2B184F),
        const Color(0xFF191038),
        AppColors.deepNavy,
      ];
    } else {
      // Deep Midnight Nebula (9 PM - 5 AM) - Deep celestial starry sky
      return [
        const Color(0xFF0C132E),
        const Color(0xFF070B1E),
        AppColors.deepNavy,
      ];
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    if (hour >= 17 && hour < 21) return 'Good evening';
    return 'Goodnight';
  }

  String _getGreetingSubtitle(String? adminWelcomeMessage) {
    if (adminWelcomeMessage != null &&
        adminWelcomeMessage.trim().isNotEmpty &&
        adminWelcomeMessage.trim() != 'Welcome!') {
      return adminWelcomeMessage.trim();
    }
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Start your day with a gentle story';
    if (hour >= 12 && hour < 17) return 'Peaceful tales for quiet time';
    if (hour >= 17 && hour < 21) return 'Unwind and get ready for sleep';
    return 'Time for a bedtime story';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(publishedStoriesProvider);
    final playlistsAsync = ref.watch(publishedPlaylistsProvider);
    final configAsync = ref.watch(appConfigProvider);

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: RefreshIndicator(
        color: AppColors.warmGold,
        backgroundColor: AppColors.surfaceLight,
        onRefresh: () async {
          // Invalidate providers to force refetch
          ref.invalidate(publishedStoriesProvider);
          ref.invalidate(publishedPlaylistsProvider);
          // Small delay so user sees the refresh indicator
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // ── Animated background with stars & celestial elements ──
          SliverToBoxAdapter(
            child: Stack(
              children: [
                // Twilight / Midnight Dynamic Gradient background
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: _getHeaderGradientColors(),
                      ),
                    ),
                  ),
                ),
                // Interactive Starfield with Shooting Stars on Tap
                const Positioned.fill(
                  child: _StarField(),
                ),
                // Greeting & Bedtime Shortcuts Content
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Greeting Row: Pulsing Golden Crescent Moon + Greeting + Subtitle
                        Row(
                          children: [
                            const _CelestialMoon(),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getGreeting(),
                                    style: AppTypography.displaySmall.copyWith(
                                      color: AppColors.moonlightWhite,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _getGreetingSubtitle(configAsync.value?.welcomeMessage),
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.lavender,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // 1-Tap Quick Bedtime Atmosphere Shortcuts
                        const _BedtimeShortcutsBar(),
                        const SizedBox(height: 14),

                        // Now Playing Playlist or Unified Spotlight Hero Card
                        ValueListenableBuilder<Playlist?>(
                          valueListenable:
                              AudioPlayerService.instance.currentPlaylist,
                          builder: (context, currentPlaylist, _) {
                            return ValueListenableBuilder<Story?>(
                              valueListenable:
                                  AudioPlayerService.instance.currentStory,
                              builder: (context, currentStory, _) {
                                if (currentPlaylist != null &&
                                    currentStory != null) {
                                  return _NowPlayingPlaylistCard(
                                    playlist: currentPlaylist,
                                    story: currentStory,
                                  );
                                }

                                return storiesAsync.when(
                                  data: (stories) {
                                    // Check if admin specified a custom pick story ID
                                    final pickId = configAsync.value?.barbaraPickStoryId;
                                    Story? chosenStory;
                                    if (pickId != null && pickId.isNotEmpty) {
                                      final matches = stories.where((s) => s.id == pickId && !s.isVideo);
                                      if (matches.isNotEmpty) chosenStory = matches.first;
                                    }

                                    if (chosenStory == null) {
                                      final featured = stories.where((s) => s.isFeatured && !s.isVideo);
                                      if (featured.isNotEmpty) {
                                        chosenStory = featured.first;
                                      } else {
                                        final audioStories = stories.where((s) => !s.isVideo);
                                        if (audioStories.isNotEmpty) {
                                          chosenStory = audioStories.first;
                                        }
                                      }
                                    }

                                    if (chosenStory == null) {
                                      return const SizedBox.shrink();
                                    }

                                    return _UnifiedSpotlightHeroCard(
                                      story: chosenStory,
                                      config: configAsync.value,
                                    );
                                  },
                                  loading: () => _buildFeaturedSkeleton(),
                                  error: (_, __) => const SizedBox.shrink(),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Trending Stories ──
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: _SectionHeader(
                label: 'TRENDING',
                title: 'Popular Stories',
                icon: Icons.local_fire_department_rounded,
                iconColor: AppColors.warmGold,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 242,
              child: storiesAsync.when(
                data: (stories) {
                  final audioStories = stories.where((s) => !s.isVideo).toList();
                  if (audioStories.isEmpty) {
                    return const Center(
                      child: Text(
                        'No stories yet',
                        style: AppTypography.bodyMedium,
                      ),
                    );
                  }
                  // Sort by play count for trending
                  final trending = List<Story>.from(audioStories)
                    ..sort((a, b) => b.playCount.compareTo(a.playCount));
                  return ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white,
                          Colors.white,
                          Color(0x00FFFFFF),
                        ],
                        stops: [0.0, 0.91, 1.0],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(20, 2, 20, 6),
                      physics: const BouncingScrollPhysics(),
                      itemCount: trending.length,
                      itemBuilder: (_, i) => StoryCard(story: trending[i]),
                    ),
                  );
                },
                loading: () => _buildHorizontalSkeleton(),
                error: (e, _) => Center(
                  child: Text(
                    'Could not load stories',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Storytime with Barbara (Video Stories) ──
          SliverToBoxAdapter(
            child: _StorytimeWithBarbaraShelf(
              storiesAsync: storiesAsync,
              config: configAsync.value,
            ),
          ),

          // ── All Stories ──
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 28, 20, 14),
              child: _SectionHeader(
                label: 'LIBRARY',
                title: 'All Stories',
                icon: Icons.auto_stories_rounded,
                iconColor: AppColors.lavender,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 242,
              child: storiesAsync.when(
                data: (stories) {
                  final audioStories = stories.where((s) => !s.isVideo).toList();
                  if (audioStories.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white,
                          Colors.white,
                          Color(0x00FFFFFF),
                        ],
                        stops: [0.0, 0.91, 1.0],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(20, 2, 20, 6),
                      physics: const BouncingScrollPhysics(),
                      itemCount: audioStories.length,
                      itemBuilder: (_, i) => StoryCard(story: audioStories[i]),
                    ),
                  );
                },
                loading: () => _buildHorizontalSkeleton(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),

          // ── Barbara's Bedtime Wisdom Card ──
          SliverToBoxAdapter(
            child: _BarbaraBedtimeWisdomCard(config: configAsync.value),
          ),

          // ── Playlists ──
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 28, 20, 14),
              child: _SectionHeader(
                label: 'COLLECTIONS',
                title: 'Playlists',
                icon: Icons.queue_music_rounded,
                iconColor: AppColors.softGold,
              ),
            ),
          ),
          playlistsAsync.when(
            data: (playlists) {
              if (playlists.isEmpty) {
                return const SliverToBoxAdapter(
                  child: SizedBox.shrink(),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => PlaylistCard(playlist: playlists[i]),
                    childCount: playlists.length,
                  ),
                ),
              );
            },
            loading: () => SliverToBoxAdapter(
              child: _buildPlaylistSkeleton(),
            ),
            error: (_, __) => const SliverToBoxAdapter(
              child: SizedBox.shrink(),
            ),
          ),

          // Bottom spacing for mini-player
          const SliverToBoxAdapter(
            child: SizedBox(height: 130),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildFeaturedSkeleton() {
    return const FeaturedCardSkeleton();
  }

  Widget _buildHorizontalSkeleton() {
    return const StoryRowSkeleton();
  }

  Widget _buildPlaylistSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(
          3,
          (_) => const PlaylistCardSkeleton(),
        ),
      ),
    );
  }
}

// ── Section Header ──
class _SectionHeader extends StatelessWidget {
  final String label;
  final String title;
  final IconData icon;
  final Color iconColor;

  const _SectionHeader({
    required this.label,
    required this.title,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.sectionLabel,
            ),
            Text(
              title,
              style: AppTypography.headlineLarge,
            ),
          ],
        ),
      ],
    );
  }
}

// ── Unified Spotlight Hero Card (The Unified Sanctuary Hero) ──
class _UnifiedSpotlightHeroCard extends StatelessWidget {
  final Story story;
  final AppConfig? config;

  const _UnifiedSpotlightHeroCard({
    required this.story,
    this.config,
  });

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final greeting = config?.barbaraEveningGreeting ??
        "Good evening. Put the day aside, take a slow breath, and let's get you ready for rest.";
    final audioUrl = config?.barbaraGreetingAudioUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF231A4E),
            Color(0xFF140F2D),
          ],
        ),
        border: Border.all(
          color: AppColors.warmGold.withValues(alpha: 0.22),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Header: Barbara's Evening Greeting Note ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Small Glowing Avatar
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.warmGold, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.warmGold.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/barbara_avatar.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Text('🎙️', style: TextStyle(fontSize: 15)),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'A Note from Barbara',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.warmGold,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '"$greeting"',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.moonlightWhite.withValues(alpha: 0.9),
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (audioUrl != null && audioUrl.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      AudioPlayerService.instance.playStory(
                        Story(
                          id: 'barbara_greeting',
                          title: "Barbara's Bedtime Greeting",
                          description: greeting,
                          narrator: 'Barbara',
                          duration: 15,
                          category: 'Greeting',
                          tags: const ['greeting', 'welcome'],
                          audioUrl: audioUrl,
                          coverImageUrl: 'covers/toad_and_butterfly.jpg',
                          isFeatured: false,
                          isPublished: true,
                          playCount: 1,
                          sortOrder: 0,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.warmGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.warmGold.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.volume_up_rounded, color: AppColors.warmGold, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Listen',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.warmGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Divider ──
          Divider(
            color: Colors.white.withValues(alpha: 0.08),
            height: 1,
            thickness: 0.8,
          ),

          // ── Story Recommendation Body ──
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.lightImpact();
              context.push('/story/${story.id}');
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Row(
                children: [
                  // Cover Art Thumbnail
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: CachedNetworkImage(
                        imageUrl: story.coverImageUrl,
                        memCacheWidth: 300,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Shimmer.fromColors(
                          baseColor: AppColors.surfaceLight,
                          highlightColor: AppColors.cardBackgroundLight,
                          child: Container(color: AppColors.surfaceLight),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.surfaceLight,
                          child: const Icon(
                            Icons.nightlight_round,
                            color: AppColors.warmGold,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Metadata & Description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warmGold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.warmGold.withValues(alpha: 0.3),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                "TONIGHT'S PICK",
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.warmGold,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            if (story.isVideo) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warmGold.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.warmGold.withValues(alpha: 0.5),
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
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (story.duration > 0) ...[
                              const SizedBox(width: 6),
                              Text(
                                _formatDuration(story.duration),
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.lavender.withValues(alpha: 0.7),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          story.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.headlineSmall.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.moonlightWhite,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Narrated by ${story.narrator}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.lavender.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Floating Refined Play/Pause Button
                  ValueListenableBuilder<Story?>(
                    valueListenable: AudioPlayerService.instance.currentStory,
                    builder: (_, currentStory, __) {
                      final isCurrent = currentStory?.id == story.id;
                      return ValueListenableBuilder<bool>(
                        valueListenable: AudioPlayerService.instance.isPlaying,
                        builder: (_, isPlaying, __) {
                          final showPause = isCurrent && isPlaying;
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
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.warmGold,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.warmGold.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                showPause
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: AppColors.deepNavy,
                                size: 24,
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
          ),
        ],
      ),
    );
  }
}

// ── Storytime with Barbara (Video Stories Shelf) ──
class _StorytimeWithBarbaraShelf extends StatelessWidget {
  final AsyncValue<List<Story>> storiesAsync;
  final AppConfig? config;

  const _StorytimeWithBarbaraShelf({required this.storiesAsync, this.config});

  @override
  Widget build(BuildContext context) {
    return storiesAsync.when(
      data: (stories) {
        final videoStories = stories.where((s) => s.isVideo).toList();
        final fallbackVideoUrl = config?.barbaraVideoUrl;

        if (videoStories.isEmpty && (fallbackVideoUrl == null || fallbackVideoUrl.isEmpty)) {
          return const SizedBox.shrink();
        }

        final targetStory = videoStories.isNotEmpty ? videoStories.first : stories.first;
        final effectiveVideoUrl = videoStories.isNotEmpty
            ? videoStories.first.effectiveVideoUrl
            : fallbackVideoUrl!;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader(
                label: 'VIDEO STORYTIME',
                title: 'Watch Barbara Read',
                icon: Icons.videocam_rounded,
                iconColor: AppColors.warmGold,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (_) => VideoStoryPlayerScreen(
                        story: targetStory,
                        videoUrl: effectiveVideoUrl,
                        title: config?.barbaraVideoTitle ?? targetStory.title,
                        narrator: 'Barbara',
                        coverImageUrl: targetStory.coverImageUrl,
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 170,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: AppColors.surfaceLight,
                    image: targetStory.coverImageUrl.isNotEmpty
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(
                              targetStory.coverImageUrl,
                              maxWidth: 700,
                            ),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.black.withValues(alpha: 0.45),
                              BlendMode.darken,
                            ),
                          )
                        : null,
                    border: Border.all(
                      color: AppColors.warmGold.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                const Color(0xFF0D0A1C).withValues(alpha: 0.85),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.warmGold,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.warmGold.withValues(alpha: 0.5),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: AppColors.deepNavy,
                            size: 38,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 14,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    config?.barbaraVideoTitle ?? targetStory.title,
                                    style: AppTypography.headlineMedium.copyWith(
                                      color: AppColors.moonlightWhite,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Text(
                                    'Storytime with Barbara • Watch & Listen',
                                    style: TextStyle(color: AppColors.lavender, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xCC130E2E),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.warmGold.withValues(alpha: 0.4),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.videocam_rounded, color: AppColors.warmGold, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'VIDEO',
                                    style: TextStyle(
                                      color: AppColors.warmGold,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── Barbara Bedtime Wisdom Card ──
class _BarbaraBedtimeWisdomCard extends StatelessWidget {
  final AppConfig? config;

  const _BarbaraBedtimeWisdomCard({this.config});

  @override
  Widget build(BuildContext context) {
    final wisdom = config?.barbaraBedtimeWisdom ??
        "Barbara's Bedtime Ritual: Dim the lamps 30 minutes before bed, keep a glass of warm water nearby, and let go of tomorrow's to-do list.";

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF26194A),
              Color(0xFF130E28),
            ],
          ),
          border: Border.all(
            color: AppColors.warmGold.withValues(alpha: 0.28),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('✨', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "BARBARA'S BEDTIME WISDOM",
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.warmGold,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    wisdom,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.moonlightWhite,
                      height: 1.5,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Now Playing Playlist Card ──
class _NowPlayingPlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final Story story;

  const _NowPlayingPlaylistCard({
    required this.playlist,
    required this.story,
  });

  @override
  Widget build(BuildContext context) {
    final service = AudioPlayerService.instance;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/story/${story.id}');
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2B1855),
              Color(0xFF140D2F),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.warmGold.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepViolet.withValues(alpha: 0.6),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: AppColors.warmGold.withValues(alpha: 0.15),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            // Playlist / Story Cover art
            Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CachedNetworkImage(
                      imageUrl: playlist.coverImageUrl.isNotEmpty
                          ? playlist.coverImageUrl
                          : story.coverImageUrl,
                      memCacheWidth: 260,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppColors.surfaceLight),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.surfaceLight,
                        child: const Icon(
                          Icons.queue_music_rounded,
                          color: AppColors.warmGold,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 3,
                  right: 3,
                  child: Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Icon(
                      Icons.collections_bookmark_rounded,
                      color: AppColors.warmGold,
                      size: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            // Metadata
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warmGold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.graphic_eq_rounded,
                                color: AppColors.warmGold,
                                size: 10,
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  'NOW PLAYING PLAYLIST',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.warmGold,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 8.5,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    playlist.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headlineMedium.copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 1.5),
                  ValueListenableBuilder<int>(
                    valueListenable: service.currentQueueIndexNotifier,
                    builder: (_, qIndex, __) {
                      final total = service.playlistQueueNotifier.value.length;
                      return Text(
                        '${story.title} ${total > 0 ? "• Story ${(qIndex + 1)} of $total" : ""}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.lavender,
                          fontSize: 11,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Controls Row
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Back button
                IconButton(
                  icon: const Icon(
                    Icons.skip_previous_rounded,
                    color: AppColors.moonlightWhite,
                    size: 22,
                  ),
                  tooltip: 'Previous Story',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    service.playPrevious();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 26,
                    minHeight: 26,
                  ),
                ),
                const SizedBox(width: 3),
                // Play/Pause button
                StreamBuilder<PlayerState>(
                  stream: service.player.playerStateStream,
                  builder: (_, snapshot) {
                    final playing = snapshot.data?.playing ?? false;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        service.togglePlayPause();
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.warmGold,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.warmGold.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: AppColors.deepNavy,
                          size: 22,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 3),
                // Next button
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
                    minWidth: 26,
                    minHeight: 26,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Celestial Moon Widget ──
class _CelestialMoon extends StatefulWidget {
  const _CelestialMoon();

  @override
  State<_CelestialMoon> createState() => _CelestialMoonState();
}

class _CelestialMoonState extends State<_CelestialMoon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = _pulseController.value;
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.warmGold.withValues(alpha: 0.18 + pulse * 0.22),
                blurRadius: 14 + pulse * 8,
                spreadRadius: 2 + pulse * 3,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer golden ring halo
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.warmGold.withValues(alpha: 0.10 + pulse * 0.08),
                  border: Border.all(
                    color: AppColors.warmGold.withValues(alpha: 0.35 + pulse * 0.25),
                    width: 1.2,
                  ),
                ),
              ),
              // Golden Crescent Moon
              Transform.rotate(
                angle: -0.35,
                child: const Icon(
                  Icons.nightlight_round,
                  color: AppColors.warmGold,
                  size: 24,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Bedtime Atmosphere Shortcuts Bar (1-Tap Ambient & Timer) ──
class _BedtimeShortcutsBar extends ConsumerWidget {
  const _BedtimeShortcutsBar();

  Widget _buildChip({
    required String label,
    required String emoji,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.warmGold.withValues(alpha: 0.25)
                : AppColors.surfaceLight.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? AppColors.warmGold
                  : Colors.white.withValues(alpha: 0.15),
              width: isActive ? 1.4 : 1.0,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.warmGold.withValues(alpha: 0.3),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: isActive ? AppColors.warmGold : AppColors.moonlightWhite,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ambientService = AmbientSoundService.instance;
    final audioService = AudioPlayerService.instance;

    return ValueListenableBuilder<List<AmbientSound>>(
      valueListenable: ambientService.activeSounds,
      builder: (context, activeSounds, _) {
        final activeIds = activeSounds.map((s) => s.id).toSet();

        return SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildChip(
                label: 'Rain',
                emoji: '🌧️',
                isActive: activeIds.contains('rain'),
                onTap: () {
                  HapticFeedback.lightImpact();
                  ambientService.toggleSound('rain');
                },
              ),
              const SizedBox(width: 8),
              _buildChip(
                label: 'Waves',
                emoji: '🌊',
                isActive: activeIds.contains('ocean'),
                onTap: () {
                  HapticFeedback.lightImpact();
                  ambientService.toggleSound('ocean');
                },
              ),
              const SizedBox(width: 8),
              _buildChip(
                label: 'Fireplace',
                emoji: '🔥',
                isActive: activeIds.contains('fireplace'),
                onTap: () {
                  HapticFeedback.lightImpact();
                  ambientService.toggleSound('fireplace');
                },
              ),
              const SizedBox(width: 8),
              _buildChip(
                label: 'Wind',
                emoji: '💨',
                isActive: activeIds.contains('wind'),
                onTap: () {
                  HapticFeedback.lightImpact();
                  ambientService.toggleSound('wind');
                },
              ),
              const SizedBox(width: 8),
              // Sleep Timer shortcut
              ValueListenableBuilder<Duration?>(
                valueListenable: audioService.sleepTimerRemaining,
                builder: (context, remaining, _) {
                  final isTimerActive = remaining != null;
                  final label = isTimerActive
                      ? '${remaining.inMinutes}m left'
                      : 'Timer';
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (_) => const SleepTimerSheet(),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: isTimerActive
                              ? AppColors.warmGold.withValues(alpha: 0.25)
                              : AppColors.surfaceLight.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isTimerActive
                                ? AppColors.warmGold
                                : Colors.white.withValues(alpha: 0.15),
                            width: isTimerActive ? 1.4 : 1.0,
                          ),
                          boxShadow: isTimerActive
                              ? [
                                  BoxShadow(
                                    color: AppColors.warmGold.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 14,
                              color: isTimerActive
                                  ? AppColors.warmGold
                                  : AppColors.moonlightWhite,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              label,
                              style: AppTypography.labelMedium.copyWith(
                                color: isTimerActive
                                    ? AppColors.warmGold
                                    : AppColors.moonlightWhite,
                                fontWeight: isTimerActive
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Interactive Star Field with Shooting Stars ──
class _StarField extends StatefulWidget {
  const _StarField();

  @override
  State<_StarField> createState() => _StarFieldState();
}

class _ShootingStarData {
  final double startX;
  final double startY;
  final double length;
  final double angle;

  _ShootingStarData({
    required this.startX,
    required this.startY,
    required this.length,
    required this.angle,
  });
}

class _StarFieldState extends State<_StarField>
    with TickerProviderStateMixin {
  late final AnimationController _twinkleController;
  late final AnimationController _shootingController;
  late final List<_Star> _stars;
  _ShootingStarData? _currentShootingStar;
  Timer? _periodicShootingTimer;

  @override
  void initState() {
    super.initState();
    _twinkleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _shootingController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    final random = Random(42);
    _stars = List.generate(35, (_) {
      return _Star(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 2.2 + 0.6,
        opacity: random.nextDouble() * 0.6 + 0.2,
        phase: random.nextDouble(),
      );
    });

    // Occasional subtle background shooting star
    _periodicShootingTimer = Timer.periodic(const Duration(seconds: 14), (_) {
      if (mounted) _spawnShootingStar();
    });
  }

  void _spawnShootingStar() {
    final random = Random();
    setState(() {
      _currentShootingStar = _ShootingStarData(
        startX: 0.15 + random.nextDouble() * 0.65,
        startY: 0.05 + random.nextDouble() * 0.25,
        length: 0.25 + random.nextDouble() * 0.2,
        angle: pi / 4 + (random.nextDouble() - 0.5) * 0.2,
      );
    });
    _shootingController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _periodicShootingTimer?.cancel();
    _twinkleController.dispose();
    _shootingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        HapticFeedback.selectionClick();
        _spawnShootingStar();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_twinkleController, _shootingController]),
        builder: (_, __) {
          return RepaintBoundary(
            child: CustomPaint(
              painter: _StarPainter(
                stars: _stars,
                animValue: _twinkleController.value,
                shootingStar: _currentShootingStar,
                shootingProgress: _shootingController.isAnimating
                    ? _shootingController.value
                    : null,
              ),
              size: Size.infinite,
            ),
          );
        },
      ),
    );
  }
}

class _Star {
  final double x;
  final double y;
  final double size;
  final double opacity;
  final double phase;

  _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.phase,
  });
}

class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  final double animValue;
  final _ShootingStarData? shootingStar;
  final double? shootingProgress;

  _StarPainter({
    required this.stars,
    required this.animValue,
    this.shootingStar,
    this.shootingProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Twinkling stars
    for (final star in stars) {
      final twinkle = (sin((animValue + star.phase) * pi * 2) + 1) / 2;
      final opacity = star.opacity * (0.3 + twinkle * 0.7);
      final paint = Paint()
        ..color = AppColors.moonlightWhite.withValues(alpha: opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, star.size * 0.8);
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size,
        paint,
      );
    }

    // Shooting star / stardust streak
    if (shootingProgress != null && shootingStar != null) {
      final p = shootingProgress!;
      if (p > 0.0 && p < 1.0) {
        final currentHeadX =
            shootingStar!.startX + cos(shootingStar!.angle) * shootingStar!.length * p;
        final currentHeadY =
            shootingStar!.startY + sin(shootingStar!.angle) * shootingStar!.length * p;
        final tailProgress = (p - 0.30).clamp(0.0, 1.0);
        final currentTailX =
            shootingStar!.startX + cos(shootingStar!.angle) * shootingStar!.length * tailProgress;
        final currentTailY =
            shootingStar!.startY + sin(shootingStar!.angle) * shootingStar!.length * tailProgress;

        final startOffset =
            Offset(currentTailX * size.width, currentTailY * size.height);
        final endOffset =
            Offset(currentHeadX * size.width, currentHeadY * size.height);

        final fade = p < 0.5 ? p * 2 : (1.0 - p) * 2;
        final paint = Paint()
          ..shader = LinearGradient(
            colors: [
              AppColors.warmGold.withValues(alpha: 0.0),
              AppColors.warmGold.withValues(alpha: 0.75 * fade),
              Colors.white.withValues(alpha: 0.95 * fade),
            ],
            stops: const [0.0, 0.65, 1.0],
          ).createShader(Rect.fromPoints(startOffset, endOffset))
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round;

        canvas.drawLine(startOffset, endOffset, paint);

        // Glowing stardust head
        final glowPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.95 * fade)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(endOffset, 2.5, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) =>
      old.animValue != animValue ||
      old.shootingProgress != shootingProgress ||
      old.shootingStar != shootingStar;
}
