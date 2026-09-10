import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barbs_bedtime_stories/data/models/story.dart';
import 'package:barbs_bedtime_stories/services/audio_player_service.dart';
import 'package:barbs_bedtime_stories/widgets/mini_player.dart';
import 'package:video_player/video_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final videoStory = Story(
    id: 'the_sock_drawer',
    title: 'The Sock Drawer',
    description: 'Barbara reads The Sock Drawer',
    narrator: 'Barbara',
    duration: 300,
    category: 'Video',
    tags: const ['video'],
    audioUrl: '',
    videoUrl: 'https://example.com/the_sock_drawer.mp4',
    coverImageUrl: 'https://example.com/cover.jpg',
    isFeatured: false,
    isPublished: true,
    playCount: 1,
    sortOrder: 0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  testWidgets('Video player minimization shows MiniPlayer with working controls', (tester) async {
    final service = AudioPlayerService.instance;
    await service.stopPlayback();

    final dummyController = VideoPlayerController.networkUrl(
      Uri.parse('https://example.com/the_sock_drawer.mp4'),
    );

    // Build a mock screen containing MiniPlayer at the bottom
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Center(child: Text('Home Screen')),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: MiniPlayer(),
              ),
            ],
          ),
        ),
      ),
    );

    // Initial state: No story playing, MiniPlayer should not be visible
    expect(find.text('The Sock Drawer'), findsNothing);

    // 1. User opens VideoStoryPlayerScreen full-screen
    service.registerVideoController(dummyController, story: videoStory);
    service.isVideoPlayerFullScreen.value = true;
    await tester.pump();

    // While full-screen video is active, MiniPlayer MUST remain hidden
    expect(find.text('The Sock Drawer'), findsNothing);

    // 2. User minimizes video player (down arrow or back gesture)
    service.isVideoPlayerFullScreen.value = false;
    await tester.pump();

    // Now MiniPlayer MUST be visible with title, subtitle, Play/Pause, and Close
    expect(find.text('The Sock Drawer'), findsOneWidget);
    expect(find.text('Video Story • Barbara'), findsOneWidget);
    expect(find.byTooltip('Close Player'), findsOneWidget);

    // 3. Toggle Play/Pause from MiniPlayer
    final playPauseButton = find.byType(IconButton).at(0);
    await tester.tap(playPauseButton);
    await tester.pump();

    // 4. Tap Close button on MiniPlayer
    final closeButton = find.byTooltip('Close Player');
    await tester.tap(closeButton);
    await tester.pump();

    // MiniPlayer must disappear completely and playback state should be cleared
    expect(find.text('The Sock Drawer'), findsNothing);
    expect(service.currentStory.value, isNull);
    expect(service.activeVideoController, isNull);
  });
}
