import 'package:flutter_test/flutter_test.dart';
import 'package:barbs_bedtime_stories/data/models/story.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final audioStory1 = Story(
    id: 'story-1',
    title: 'The Toad & The Butterfly',
    description: 'A gentle bedtime fable',
    narrator: 'Barbara',
    duration: 120,
    category: 'nature',
    tags: ['sleep', 'calm'],
    audioUrl: 'https://example.com/audio1.mp3',
    coverImageUrl: 'https://example.com/cover1.jpg',
    isFeatured: true,
    isPublished: true,
    playCount: 50,
    sortOrder: 1,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final videoStory = Story(
    id: 'story-video',
    title: 'The Sock Drawer',
    description: 'Barbara reads The Sock Drawer',
    narrator: 'Barbara',
    duration: 360,
    category: 'bedtime',
    tags: ['video', 'reading'],
    audioUrl: 'https://example.com/video.mp4',
    coverImageUrl: 'https://example.com/cover_video.jpg',
    videoUrl: 'https://example.com/video.mp4',
    isFeatured: false,
    isPublished: true,
    playCount: 100,
    sortOrder: 2,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final audioStory2 = Story(
    id: 'story-2',
    title: 'A Day Closes in the Woods',
    description: 'A quiet woodland rest',
    narrator: 'Barbara',
    duration: 240,
    category: 'nature',
    tags: ['woods', 'evening'],
    audioUrl: 'https://example.com/audio2.mp3',
    coverImageUrl: 'https://example.com/cover2.jpg',
    isFeatured: false,
    isPublished: true,
    playCount: 30,
    sortOrder: 3,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final allStories = [audioStory1, videoStory, audioStory2];

  group('Story Video Separation Logic', () {
    test('General audio stories list excludes video stories', () {
      final audioStories = allStories.where((s) => !s.isVideo).toList();

      expect(audioStories.length, 2);
      expect(audioStories.map((s) => s.id), containsAll(['story-1', 'story-2']));
      expect(audioStories.map((s) => s.id), isNot(contains('story-video')));
    });

    test('Dedicated video storytime shelf correctly identifies video stories', () {
      final videoStories = allStories.where((s) => s.isVideo).toList();

      expect(videoStories.length, 1);
      expect(videoStories.first.id, 'story-video');
      expect(videoStories.first.title, 'The Sock Drawer');
    });

    test('Trending audio stories list sorts only audio stories by playCount', () {
      final audioStories = allStories.where((s) => !s.isVideo).toList();
      final trending = List<Story>.from(audioStories)
        ..sort((a, b) => b.playCount.compareTo(a.playCount));

      expect(trending.first.id, 'story-1');
      expect(trending.last.id, 'story-2');
      expect(trending.map((s) => s.id), isNot(contains('story-video')));
    });
  });
}
