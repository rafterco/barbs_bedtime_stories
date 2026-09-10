import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:barbs_bedtime_stories/core/theme/app_colors.dart';

/// Shimmer skeleton loading widgets that match layout shapes.
/// Use instead of CircularProgressIndicator for premium feel.

class SkeletonContainer extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const SkeletonContainer({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Wraps children in a shimmer effect using the app's colour palette.
class ShimmerWrap extends StatelessWidget {
  final Widget child;

  const ShimmerWrap({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceLight,
      highlightColor: AppColors.lavender.withValues(alpha: 0.15),
      period: const Duration(milliseconds: 1500),
      child: child,
    );
  }
}

/// Skeleton for a single story card (used in trending stories).
class StoryCardSkeleton extends StatelessWidget {
  const StoryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrap(
      child: Container(
        width: 148,
        margin: const EdgeInsets.only(right: 12),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonContainer(
              width: 148,
              height: 148,
              borderRadius: 16,
            ),
            SizedBox(height: 10),
            SkeletonContainer(
              width: 120,
              height: 14,
              borderRadius: 6,
            ),
            SizedBox(height: 6),
            SkeletonContainer(
              width: 80,
              height: 12,
              borderRadius: 6,
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for the featured story hero card.
class FeaturedCardSkeleton extends StatelessWidget {
  const FeaturedCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShimmerWrap(
      child: SkeletonContainer(
        height: 200,
        borderRadius: 20,
      ),
    );
  }
}

/// Skeleton for a playlist card.
class PlaylistCardSkeleton extends StatelessWidget {
  const PlaylistCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrap(
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        child: const Row(
          children: [
            SkeletonContainer(
              width: 80,
              height: 80,
              borderRadius: 14,
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonContainer(
                    height: 16,
                    borderRadius: 6,
                  ),
                  SizedBox(height: 8),
                  SkeletonContainer(
                    width: 140,
                    height: 12,
                    borderRadius: 6,
                  ),
                  SizedBox(height: 6),
                  SkeletonContainer(
                    width: 80,
                    height: 12,
                    borderRadius: 6,
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

/// Skeleton for the browse screen grid.
class BrowseGridSkeleton extends StatelessWidget {
  const BrowseGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrap(
      child: Column(
        children: [
          // Category chips skeleton
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (_, __) => const Padding(
                padding: EdgeInsets.only(right: 8),
                child: SkeletonContainer(
                  width: 80,
                  height: 36,
                  borderRadius: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Grid skeleton
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.75,
            ),
            itemCount: 4,
            itemBuilder: (_, __) => const SkeletonContainer(
              borderRadius: 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// A horizontal row of story card skeletons.
class StoryRowSkeleton extends StatelessWidget {
  final int count;

  const StoryRowSkeleton({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: count,
        itemBuilder: (_, __) => const StoryCardSkeleton(),
      ),
    );
  }
}
