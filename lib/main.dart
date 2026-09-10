import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'app.dart';
import 'core/router/app_router.dart';
import 'services/audio_player_service.dart';
import 'services/onboarding_service.dart';
import 'services/favorites_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for bedtime use
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Dark status bar for the dreamy theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF1A1640),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase.initializeApp error: $e');
  }

  // Initialize services with error resilience
  try {
    await AudioPlayerService.instance.init();
  } catch (e) {
    debugPrint('AudioPlayerService init error: $e');
  }

  try {
    await FavoritesService.instance.init();
  } catch (e) {
    debugPrint('FavoritesService init error: $e');
  }

  // Check onboarding status and set initial route
  bool onboardingComplete = false;
  try {
    onboardingComplete = await OnboardingService.isOnboardingComplete();
  } catch (e) {
    debugPrint('OnboardingService error: $e');
  }

  AppRouter.init(
    initialLocation: onboardingComplete ? '/' : '/onboarding',
  );

  runApp(
    const ProviderScope(
      child: BarbsBedtimeStoriesApp(),
    ),
  );
}
