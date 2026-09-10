import 'package:flutter_test/flutter_test.dart';
import 'package:barbs_bedtime_stories/services/audio_player_service.dart';
import 'package:barbs_bedtime_stories/data/models/story.dart';
import 'package:video_player/video_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final videoStory = Story(
    id: 'video_1',
    title: 'The Sock Drawer',
    description: 'Video Story',
    narrator: 'Barbara',
    duration: 300,
    category: 'Video',
    tags: const ['video'],
    audioUrl: '',
    videoUrl: 'https://example.com/video.mp4',
    coverImageUrl: 'https://example.com/cover.jpg',
    isFeatured: false,
    isPublished: true,
    playCount: 1,
    sortOrder: 0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  test('Video playback lifecycle: registration, minimization, and stopPlayback', () async {
    final service = AudioPlayerService.instance;
    await service.stopPlayback();

    final dummyController = VideoPlayerController.networkUrl(
      Uri.parse('https://example.com/video.mp4'),
    );

    // 1. Register video controller
    service.registerVideoController(dummyController, story: videoStory);
    service.isVideoPlayerFullScreen.value = true;

    expect(service.activeVideoController, equals(dummyController));
    expect(service.currentStory.value?.id, equals(videoStory.id));
    expect(
      service.isVideoPlayerFullScreen.value,
      isTrue,
      reason: 'MiniPlayer must remain hidden while video is full-screen',
    );

    // 2. Minimizing video player
    service.isVideoPlayerFullScreen.value = false;
    expect(service.isVideoPlayerFullScreen.value, isFalse);
    expect(
      service.currentStory.value?.id,
      equals(videoStory.id),
      reason: 'currentStory must stay non-null so MiniPlayer is displayed when minimized',
    );
    expect(
      service.activeVideoController,
      equals(dummyController),
      reason: 'activeVideoController must remain available to MiniPlayer for play/pause/close controls',
    );

    // 3. Stopping playback completely (e.g. user taps Close button on MiniPlayer or VideoPlayer)
    await service.stopPlayback();
    expect(service.currentStory.value, isNull);
    expect(service.activeVideoController, isNull);
    expect(service.isVideoPlayerFullScreen.value, isFalse);
  });

  test('registering a new video controller stops previous active controller', () async {
    final service = AudioPlayerService.instance;
    await service.stopPlayback();

    final controller1 = VideoPlayerController.networkUrl(
      Uri.parse('https://example.com/video1.mp4'),
    );
    final controller2 = VideoPlayerController.networkUrl(
      Uri.parse('https://example.com/video2.mp4'),
    );

    service.registerVideoController(controller1, story: videoStory);
    expect(service.activeVideoController, equals(controller1));

    // Registering controller2 replaces controller1
    final story2 = Story(
      id: 'video_2',
      title: 'Video Story 2',
      description: '',
      narrator: 'Barbara',
      duration: 200,
      category: 'Video',
      tags: const ['video'],
      audioUrl: '',
      videoUrl: 'https://example.com/video2.mp4',
      coverImageUrl: '',
      isFeatured: false,
      isPublished: true,
      playCount: 1,
      sortOrder: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    service.registerVideoController(controller2, story: story2);
    expect(service.activeVideoController, equals(controller2));
    expect(service.currentStory.value?.id, equals('video_2'));

    await service.stopPlayback();
    expect(service.activeVideoController, isNull);
  });
}
