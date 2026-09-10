import 'package:cloud_firestore/cloud_firestore.dart';

class AppConfig {
  final String appName;
  final String welcomeMessage;
  final String? featuredStoryId;
  final String? featuredPlaylistId;
  final List<int> sleepTimerDefaults;
  final bool maintenanceMode;
  final String minAppVersion;
  final String latestVersion;
  final String? iosStoreUrl;
  final String? androidStoreUrl;
  final int audioTimeoutSeconds;
  final String contactEmail;

  // ── Barbara Spotlight & Dynamic Communications ──
  final String barbaraEveningGreeting;
  final String? barbaraGreetingAudioUrl;
  final String? barbaraPickStoryId;
  final String barbaraPickNote;
  final String barbaraBedtimeWisdom;
  final String? barbaraVideoUrl;
  final String barbaraVideoTitle;

  // ── Meet Barbara & About the App Content ──
  final String meetBarbaraQuote;
  final String meetBarbaraTitle;
  final String meetBarbaraStory;
  final String aboutAppMission;
  final String aboutAppStoryRequests;

  AppConfig({
    required this.appName,
    required this.welcomeMessage,
    this.featuredStoryId,
    this.featuredPlaylistId,
    required this.sleepTimerDefaults,
    required this.maintenanceMode,
    required this.minAppVersion,
    required this.latestVersion,
    this.iosStoreUrl,
    this.androidStoreUrl,
    this.audioTimeoutSeconds = 45,
    this.contactEmail = 'colinrafter82@gmail.com',
    this.barbaraEveningGreeting = "Good evening. Put the day aside, take a slow breath, and let's get you ready for rest.",
    this.barbaraGreetingAudioUrl,
    this.barbaraPickStoryId,
    this.barbaraPickNote = 'Tonight, let the gentle rhythm of this story quiet your mind and guide you into deep, peaceful sleep.',
    this.barbaraBedtimeWisdom = "Barbara's Bedtime Ritual: Dim the lamps 30 minutes before bed, keep a glass of warm water nearby, and let go of tomorrow's to-do list.",
    this.barbaraVideoUrl,
    this.barbaraVideoTitle = 'Storytime with Barbara: The Toad & The Butterfly',
    this.meetBarbaraQuote = '"A quiet place for your busy mind to go before sleep."',
    this.meetBarbaraTitle = 'A bit about Barb',
    this.meetBarbaraStory =
        'Barb has spent much of her career helping people find their way toward greater well-being, drawing on her background in Psychology and Therapeutic Recreation. As a rehabilitation therapist, Barb has built her practice on goal driven activation and art-based expressive therapies to encourage emotional regulation, cognitive rehab, and connection. A large part of her work with individuals living with brain injury has also included coaching clients in sleep hygiene and healthy sleep routines, as well as using art-based expressive therapies to encourage creativity, connection, and self-expression.\n\nBarb has seen how deeply sleep can affect our mood, energy, thinking, and ability to enjoy everyday life. The development of “Sleep Stories” stems from a genuine desire to help people discover simple, practical ways to sleep better—and feel better, too.\n\nA quiet place for your busy mind to go before sleep.\nGood sleep is essential to our well-being, helping support memory, learning, mood, concentration, and our ability to manage the demands of everyday life. Yet for many of us, slowing down enough to fall asleep can be surprisingly difficult. A calming bedtime routine and relaxing activities can help create the transition from wakefulness to rest. This app offers adults a gentle way to step away from the busyness of the day through engaging, soothing stories written especially for bedtime. Settle in, let the story take you somewhere else, and give your busy mind a quiet place to go before sleep.',
    this.aboutAppMission = 'Good sleep is essential to our well-being, helping support memory, learning, mood, concentration, and our ability to manage the demands of everyday life. Yet for many of us, slowing down enough to fall asleep can be surprisingly difficult. A calming bedtime routine and relaxing activities can help create the transition from wakefulness to rest. This app offers adults a gentle way to step away from the busyness of the day through engaging, soothing stories written especially for bedtime. Settle in, let the story take you somewhere else, and give your busy mind a quiet place to go before sleep.',
    this.aboutAppStoryRequests = "Have a favourite childhood tale or a tranquil bedtime theme you'd like Barbara to record? We would love to hear from you.",
  });

  factory AppConfig.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final rawTimer = data['sleepTimerDefaults'] ??
        data['sleepTimerOptions'] ??
        data['timerOptions'] ??
        data['sleepTimer'] ??
        data['sleepTimers'] ??
        data['timers'] ??
        data['timer_defaults'] ??
        data['sleep_timer_defaults'];

    List<int> parsedTimers = [15, 30, 45, 60];
    if (rawTimer is List) {
      final list = rawTimer
          .map((e) => int.tryParse(e.toString().trim()) ?? 0)
          .where((e) => e > 0)
          .toList();
      if (list.isNotEmpty) parsedTimers = list;
    } else if (rawTimer is String) {
      final list = rawTimer
          .split(RegExp(r'[,;|\s]+'))
          .map((e) => int.tryParse(e.trim()) ?? 0)
          .where((e) => e > 0)
          .toList();
      if (list.isNotEmpty) parsedTimers = list;
    }

    return AppConfig(
      appName: data['appName'] as String? ?? "Barbara's Bedtime Stories",
      welcomeMessage: data['welcomeMessage'] as String? ?? 'Welcome!',
      featuredStoryId: data['featuredStoryId'] as String?,
      featuredPlaylistId: data['featuredPlaylistId'] as String?,
      sleepTimerDefaults: parsedTimers,
      maintenanceMode: data['maintenanceMode'] as bool? ?? false,
      minAppVersion: data['minAppVersion'] as String? ?? '1.0.0',
      latestVersion: data['latestVersion'] as String? ?? '1.0.0',
      iosStoreUrl: data['iosStoreUrl'] as String?,
      androidStoreUrl: data['androidStoreUrl'] as String?,
      audioTimeoutSeconds: (data['audioTimeoutSeconds'] as num?)?.toInt() ?? 45,
      contactEmail: data['contactEmail'] as String? ?? 'colinrafter82@gmail.com',
      barbaraEveningGreeting: data['barbaraEveningGreeting'] as String? ??
          "Good evening. Put the day aside, take a slow breath, and let's get you ready for rest.",
      barbaraGreetingAudioUrl: data['barbaraGreetingAudioUrl'] as String?,
      barbaraPickStoryId: data['barbaraPickStoryId'] as String? ?? data['featuredStoryId'] as String?,
      barbaraPickNote: data['barbaraPickNote'] as String? ??
          'Tonight, let the gentle rhythm of this story quiet your mind and guide you into deep, peaceful sleep.',
      barbaraBedtimeWisdom: data['barbaraBedtimeWisdom'] as String? ??
          "Barbara's Bedtime Ritual: Dim the lamps 30 minutes before bed, keep a glass of warm water nearby, and let go of tomorrow's to-do list.",
      barbaraVideoUrl: data['barbaraVideoUrl'] as String?,
      barbaraVideoTitle: data['barbaraVideoTitle'] as String? ??
          'Storytime with Barbara: The Toad & The Butterfly',
      meetBarbaraQuote: () {
        final q = (data['meetBarbaraQuote'] as String?)?.trim();
        if (q != null && q.isNotEmpty && !q.contains('Whenever the night feels long')) {
          return q;
        }
        return '"A quiet place for your busy mind to go before sleep."';
      }(),
      meetBarbaraTitle: () {
        final t = (data['meetBarbaraTitle'] as String?)?.trim();
        if (t != null && t.isNotEmpty && !t.contains('Heart of Your Bedtime')) {
          return t;
        }
        return 'A bit about Barb';
      }(),
      meetBarbaraStory: () {
        final s = (data['meetBarbaraStory'] as String?)?.trim();
        if (s != null && s.isNotEmpty && !s.contains('born from a simple belief')) {
          return s;
        }
        return 'Barb has spent much of her career helping people find their way toward greater well-being, drawing on her background in Psychology and Therapeutic Recreation. As a rehabilitation therapist, Barb has built her practice on goal driven activation and art-based expressive therapies to encourage emotional regulation, cognitive rehab, and connection. A large part of her work with individuals living with brain injury has also included coaching clients in sleep hygiene and healthy sleep routines, as well as using art-based expressive therapies to encourage creativity, connection, and self-expression.\n\nBarb has seen how deeply sleep can affect our mood, energy, thinking, and ability to enjoy everyday life. The development of “Sleep Stories” stems from a genuine desire to help people discover simple, practical ways to sleep better—and feel better, too.\n\nA quiet place for your busy mind to go before sleep.\nGood sleep is essential to our well-being, helping support memory, learning, mood, concentration, and our ability to manage the demands of everyday life. Yet for many of us, slowing down enough to fall asleep can be surprisingly difficult. A calming bedtime routine and relaxing activities can help create the transition from wakefulness to rest. This app offers adults a gentle way to step away from the busyness of the day through engaging, soothing stories written especially for bedtime. Settle in, let the story take you somewhere else, and give your busy mind a quiet place to go before sleep.';
      }(),
      aboutAppMission: data['aboutAppMission'] as String? ??
          'Good sleep is essential to our well-being, helping support memory, learning, mood, concentration, and our ability to manage the demands of everyday life. Yet for many of us, slowing down enough to fall asleep can be surprisingly difficult. A calming bedtime routine and relaxing activities can help create the transition from wakefulness to rest. This app offers adults a gentle way to step away from the busyness of the day through engaging, soothing stories written especially for bedtime. Settle in, let the story take you somewhere else, and give your busy mind a quiet place to go before sleep.',
      aboutAppStoryRequests: data['aboutAppStoryRequests'] as String? ??
          "Have a favourite childhood tale or a tranquil bedtime theme you'd like Barbara to record? We would love to hear from you.",
    );
  }
}
