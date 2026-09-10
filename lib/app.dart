import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barbs_bedtime_stories/core/theme/app_theme.dart';
import 'package:barbs_bedtime_stories/core/router/app_router.dart';
import 'package:barbs_bedtime_stories/data/providers.dart';
import 'package:barbs_bedtime_stories/services/ambient_sound_service.dart';
import 'package:barbs_bedtime_stories/services/audio_player_service.dart';

class BarbsBedtimeStoriesApp extends ConsumerStatefulWidget {
  const BarbsBedtimeStoriesApp({super.key});

  @override
  ConsumerState<BarbsBedtimeStoriesApp> createState() =>
      _BarbsBedtimeStoriesAppState();
}

class _BarbsBedtimeStoriesAppState extends ConsumerState<BarbsBedtimeStoriesApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      AmbientSoundService.instance.stopAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sync dynamic timeout from Firestore configuration
    ref.listen(appConfigProvider, (previous, next) {
      next.whenData((config) {
        if (config != null) {
          AudioPlayerService.instance
              .updateAudioTimeout(config.audioTimeoutSeconds);
        }
      });
    });

    return MaterialApp.router(
      title: "Barbara's Bedtime Stories",
      theme: AppTheme.darkTheme,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
