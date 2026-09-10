import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:barbs_bedtime_stories/core/theme/app_colors.dart';
import 'package:barbs_bedtime_stories/core/theme/app_typography.dart';
import 'package:barbs_bedtime_stories/data/models/app_config.dart';
import 'package:barbs_bedtime_stories/data/models/story.dart';
import 'package:barbs_bedtime_stories/data/models/testimonial.dart';
import 'package:barbs_bedtime_stories/data/providers.dart';
import 'package:barbs_bedtime_stories/data/repositories/testimonial_repository.dart';
import 'package:barbs_bedtime_stories/features/player/video_story_player_screen.dart';

class BarbScreen extends ConsumerWidget {
  const BarbScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(appConfigProvider);
    final config = configAsync.valueOrNull;

    final storiesAsync = ref.watch(publishedStoriesProvider);
    final stories = storiesAsync.valueOrNull ?? [];
    final videoStories = stories.where((s) => s.isVideo).toList();
    final fallbackVideoUrl = config?.barbaraVideoUrl;

    final rawQuote = config?.meetBarbaraQuote.trim();
    final quote = (rawQuote != null && rawQuote.isNotEmpty && !rawQuote.contains('Whenever the night feels long'))
        ? rawQuote
        : '"A quiet place for your busy mind to go before sleep."';

    final rawTitle = config?.meetBarbaraTitle.trim();
    final title = (rawTitle != null && rawTitle.isNotEmpty && !rawTitle.contains('Heart of Your Bedtime'))
        ? rawTitle
        : 'A bit about Barb';

    final rawStory = config?.meetBarbaraStory.trim();
    final story = (rawStory != null && rawStory.isNotEmpty && !rawStory.contains('born from a simple belief'))
        ? rawStory
        : 'Barb has spent much of her career helping people find their way toward greater well-being, drawing on her background in Psychology and Therapeutic Recreation. As a rehabilitation therapist, Barb has built her practice on goal driven activation and art-based expressive therapies to encourage emotional regulation, cognitive rehab, and connection. A large part of her work with individuals living with brain injury has also included coaching clients in sleep hygiene and healthy sleep routines, as well as using art-based expressive therapies to encourage creativity, connection, and self-expression.\n\nBarb has seen how deeply sleep can affect our mood, energy, thinking, and ability to enjoy everyday life. The development of “Sleep Stories” stems from a genuine desire to help people discover simple, practical ways to sleep better—and feel better, too.\n\nA quiet place for your busy mind to go before sleep.\nGood sleep is essential to our well-being, helping support memory, learning, mood, concentration, and our ability to manage the demands of everyday life. Yet for many of us, slowing down enough to fall asleep can be surprisingly difficult. A calming bedtime routine and relaxing activities can help create the transition from wakefulness to rest. This app offers adults a gentle way to step away from the busyness of the day through engaging, soothing stories written especially for bedtime. Settle in, let the story take you somewhere else, and give your busy mind a quiet place to go before sleep.';
    final mission = config?.aboutAppMission.isNotEmpty == true
        ? config!.aboutAppMission
        : 'Good sleep is essential to our well-being, helping support memory, learning, mood, concentration, and our ability to manage the demands of everyday life. Yet for many of us, slowing down enough to fall asleep can be surprisingly difficult. A calming bedtime routine and relaxing activities can help create the transition from wakefulness to rest. This app offers adults a gentle way to step away from the busyness of the day through engaging, soothing stories written especially for bedtime. Settle in, let the story take you somewhere else, and give your busy mind a quiet place to go before sleep.';
    final storyRequestsPrompt = config?.aboutAppStoryRequests.isNotEmpty == true
        ? config!.aboutAppStoryRequests
        : "Have a favourite childhood tale or a tranquil bedtime theme you'd like Barbara to record? We would love to hear from you.";
    final contactEmail = config?.contactEmail ?? 'colinrafter82@gmail.com';

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar ──
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.deepNavy,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF2E1A47),
                      AppColors.deepNavy,
                    ],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Center(
                    child: Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.warmGold,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.warmGold.withValues(alpha: 0.4),
                            blurRadius: 22,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/barbara_avatar.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Text('🎙️', style: TextStyle(fontSize: 34)),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Content ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'MEET THE STORYTELLER',
                    style: AppTypography.sectionLabel.copyWith(
                      fontSize: 11,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Barbara',
                    style: AppTypography.headlineLarge.copyWith(
                      color: AppColors.moonlightWhite,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Voice, Storyteller & Wellness Practitioner',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.lavender,
                      letterSpacing: 1.1,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quote Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.warmGold.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      quote,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.warmGold,
                        fontStyle: FontStyle.italic,
                        height: 1.55,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Headline & Story
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: AppTypography.headlineSmall.copyWith(
                        color: AppColors.moonlightWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    story,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.65,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Watch Barbara Read (Video Storytime) ──
                  _buildVideoStorySection(
                    context,
                    config,
                    stories,
                    videoStories,
                    fallbackVideoUrl,
                  ),

                  // ── Mission Card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF261D52),
                          AppColors.surfaceLight.withValues(alpha: 0.4),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.lavender.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.nightlight_round, color: AppColors.warmGold, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Our Mission',
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.warmGold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          mission,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.moonlightWhite.withValues(alpha: 0.85),
                            height: 1.55,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // ── Listener Testimonials ──
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.warmGold, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Kind Words from Listeners',
                        style: AppTypography.headlineSmall.copyWith(
                          color: AppColors.moonlightWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 19,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  StreamBuilder<List<Testimonial>>(
                    stream: TestimonialRepository.instance.watchTestimonials(),
                    builder: (context, snapshot) {
                      final testimonials = snapshot.data ?? Testimonial.defaultTestimonials;
                      if (testimonials.isEmpty) return const SizedBox.shrink();
                      return Column(
                        children: testimonials.map((t) => _buildTestimonialCard(t)).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // ── Story Requests / Contact ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.lavender.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '💌',
                          style: TextStyle(fontSize: 28),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Story Requests & Notes for Barb',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.moonlightWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          storyRequestsPrompt,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.lavender.withValues(alpha: 0.8),
                            height: 1.45,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warmGold,
                            foregroundColor: AppColors.deepNavy,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.mail_outline_rounded, size: 18),
                          label: const Text(
                            'Send Barb a Note',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () async {
                            HapticFeedback.lightImpact();
                            final uri = Uri(
                              scheme: 'mailto',
                              path: contactEmail,
                              query: 'subject=Bedtime Story Request for Barbara',
                            );
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
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
  }

  Widget _buildTestimonialCard(Testimonial t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.warmGold.withValues(alpha: 0.22),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.warmGold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    t.avatar.isNotEmpty ? t.avatar : '🌙',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.author,
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.moonlightWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      t.role,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.lavender.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  t.rating.clamp(1, 5),
                  (_) => const Icon(
                    Icons.star_rounded,
                    color: AppColors.warmGold,
                    size: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"${t.text}"',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.moonlightWhite.withValues(alpha: 0.92),
              fontStyle: FontStyle.italic,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoStorySection(
    BuildContext context,
    AppConfig? config,
    List<Story> stories,
    List<Story> videoStories,
    String? fallbackVideoUrl,
  ) {
    final hasVideo = videoStories.isNotEmpty || (fallbackVideoUrl != null && fallbackVideoUrl.isNotEmpty);
    if (!hasVideo || stories.isEmpty) return const SizedBox.shrink();

    final targetStory = videoStories.isNotEmpty ? videoStories.first : stories.first;
    final effectiveVideoUrl = videoStories.isNotEmpty ? videoStories.first.effectiveVideoUrl : fallbackVideoUrl!;
    final videoTitle = config?.barbaraVideoTitle.isNotEmpty == true
        ? config!.barbaraVideoTitle
        : targetStory.title;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.videocam_rounded, color: AppColors.warmGold, size: 22),
            const SizedBox(width: 8),
            Text(
              'Watch Barbara Read',
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.moonlightWhite,
                fontWeight: FontWeight.bold,
                fontSize: 19,
              ),
            ),
          ],
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
                  title: videoTitle,
                  narrator: 'Barbara',
                  coverImageUrl: targetStory.coverImageUrl,
                ),
              ),
            );
          },
          child: Container(
            height: 175,
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
                              videoTitle,
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
                                letterSpacing: 0.8,
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
        const SizedBox(height: 32),
      ],
    );
  }
}
