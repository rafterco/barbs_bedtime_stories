import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:barbs_bedtime_stories/core/theme/app_colors.dart';
import 'package:barbs_bedtime_stories/widgets/mini_player.dart';
import 'package:barbs_bedtime_stories/features/home/home_screen.dart';
import 'package:barbs_bedtime_stories/features/browse/browse_screen.dart';
import 'package:barbs_bedtime_stories/features/favorites/favorites_screen.dart';
import 'package:barbs_bedtime_stories/features/barb/barb_screen.dart';
import 'package:barbs_bedtime_stories/features/settings/settings_screen.dart';
import 'package:barbs_bedtime_stories/features/player/player_screen.dart';
import 'package:barbs_bedtime_stories/features/playlists/playlist_detail_screen.dart';
import 'package:barbs_bedtime_stories/features/onboarding/onboarding_screen.dart';

/// GoRouter configuration with bottom navigation shell.
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorHome =
      GlobalKey<NavigatorState>(debugLabel: 'home');
  static final _shellNavigatorBrowse =
      GlobalKey<NavigatorState>(debugLabel: 'browse');
  static final _shellNavigatorFavorites =
      GlobalKey<NavigatorState>(debugLabel: 'favorites');
  static final _shellNavigatorBarb =
      GlobalKey<NavigatorState>(debugLabel: 'barb');
  static final _shellNavigatorSettings =
      GlobalKey<NavigatorState>(debugLabel: 'settings');

  static late final GoRouter router;

  /// Initialize the router with the given initial location.
  /// Call this once at app startup.
  static void init({String initialLocation = '/'}) {
    router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      // ── Bottom nav shell ──
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(
            body: Column(
              children: [
                Expanded(child: navigationShell),
                const MiniPlayer(),
              ],
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(
                    color: AppColors.surfaceLight.withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _NavItem(
                        icon: Icons.home_rounded,
                        label: 'Home',
                        isActive: navigationShell.currentIndex == 0,
                        onTap: () => navigationShell.goBranch(
                          0,
                          initialLocation: 0 == navigationShell.currentIndex,
                        ),
                      ),
                      _NavItem(
                        icon: Icons.explore_rounded,
                        label: 'Browse',
                        isActive: navigationShell.currentIndex == 1,
                        onTap: () => navigationShell.goBranch(
                          1,
                          initialLocation: 1 == navigationShell.currentIndex,
                        ),
                      ),
                      _NavItem(
                        icon: Icons.favorite_rounded,
                        label: 'Favourites',
                        isActive: navigationShell.currentIndex == 2,
                        onTap: () => navigationShell.goBranch(
                          2,
                          initialLocation: 2 == navigationShell.currentIndex,
                        ),
                      ),
                      _NavItem(
                        icon: Icons.auto_awesome_rounded,
                        label: 'Barb',
                        isActive: navigationShell.currentIndex == 3,
                        onTap: () => navigationShell.goBranch(
                          3,
                          initialLocation: 3 == navigationShell.currentIndex,
                        ),
                      ),
                      _NavItem(
                        icon: Icons.settings_rounded,
                        label: 'Settings',
                        isActive: navigationShell.currentIndex == 4,
                        onTap: () => navigationShell.goBranch(
                          4,
                          initialLocation: 4 == navigationShell.currentIndex,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHome,
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorBrowse,
            routes: [
              GoRoute(
                path: '/browse',
                builder: (context, state) => const BrowseScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorFavorites,
            routes: [
              GoRoute(
                path: '/favorites',
                builder: (context, state) => const FavoritesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorBarb,
            routes: [
              GoRoute(
                path: '/barb',
                builder: (context, state) => const BarbScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorSettings,
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // ── Full-screen routes with dreamy transitions ──
      GoRoute(
        path: '/story/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return CustomTransitionPage(
            key: state.pageKey,
            child: PlayerScreen(storyId: id),
            transitionDuration: const Duration(milliseconds: 400),
            reverseTransitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (_, animation, __, child) {
              // Slide up + fade for player (like a modal)
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),),
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/playlist/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return CustomTransitionPage(
            key: state.pageKey,
            child: PlaylistDetailScreen(playlistId: id),
            transitionDuration: const Duration(milliseconds: 350),
            reverseTransitionDuration: const Duration(milliseconds: 250),
            transitionsBuilder: (_, animation, __, child) {
              // Slide from right + subtle scale
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.15, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),),
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animation,
                    curve: const Interval(0.0, 0.8),
                  ),
                  child: child,
                ),
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const OnboardingScreen(),
            transitionDuration: const Duration(milliseconds: 500),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
    ],
  );
  }
}

/// Custom bottom navigation item with active state animation.
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.warmGold.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.warmGold : AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.warmGold : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
