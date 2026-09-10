import 'package:flutter_test/flutter_test.dart';
import 'package:barbs_bedtime_stories/data/models/story.dart';

void main() {
  group('Story Video Detection', () {
    test('identifies video from explicit videoUrl', () {
      final story = Story(
        id: 'test_1',
        title: 'Video Story',
        description: 'Test description',
        narrator: 'Barbara',
        duration: 300,
        category: 'Bedtime',
        tags: const [],
        audioUrl: 'https://example.com/audio.mp3',
        coverImageUrl: 'https://example.com/cover.jpg',
        videoUrl: 'https://example.com/video.mp4',
        isFeatured: false,
        isPublished: true,
        playCount: 0,
        sortOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(story.isVideo, isTrue);
      expect(story.effectiveVideoUrl, equals('https://example.com/video.mp4'));
    });

    test('identifies video from audioUrl pointing to mp4', () {
      final story = Story(
        id: 'test_2',
        title: 'Uploaded MP4 as Audio',
        description: 'Test description',
        narrator: 'Barbara',
        duration: 300,
        category: 'Bedtime',
        tags: const [],
        audioUrl: 'https://firebasestorage.googleapis.com/v0/b/bucket/o/stories%2Fmy_video.mp4?alt=media&token=123',
        coverImageUrl: 'https://example.com/cover.jpg',
        videoUrl: null,
        isFeatured: false,
        isPublished: true,
        playCount: 0,
        sortOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(story.isVideo, isTrue);
      expect(story.effectiveVideoUrl, contains('my_video.mp4'));
    });

    test('identifies audio story as not video', () {
      final story = Story(
        id: 'test_3',
        title: 'Pure Audio Story',
        description: 'Test description',
        narrator: 'Barbara',
        duration: 300,
        category: 'Bedtime',
        tags: const [],
        audioUrl: 'https://firebasestorage.googleapis.com/v0/b/bucket/o/stories%2Fstory.mp3?alt=media',
        coverImageUrl: 'https://example.com/cover.jpg',
        videoUrl: null,
        isFeatured: false,
        isPublished: true,
        playCount: 0,
        sortOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(story.isVideo, isFalse);
      expect(story.effectiveVideoUrl, isEmpty);
    });

    test('isVideoUrl static helper recognizes common formats', () {
      expect(Story.isVideoUrl('https://example.com/clip.mp4'), isTrue);
      expect(Story.isVideoUrl('https://example.com/clip.MOV'), isTrue);
      expect(Story.isVideoUrl('https://example.com/clip.m4v?token=abc'), isTrue);
      expect(Story.isVideoUrl('https://example.com/clip.webm'), isTrue);
      expect(Story.isVideoUrl('https://example.com/clip.mkv'), isTrue);
      expect(Story.isVideoUrl('https://firebasestorage.googleapis.com/o/videos%2Fclip?alt=media'), isTrue);
      expect(Story.isVideoUrl('https://example.com/audio.mp3'), isFalse);
      expect(Story.isVideoUrl('https://example.com/voice.m4a'), isFalse);
      expect(Story.isVideoUrl(null), isFalse);
      expect(Story.isVideoUrl(''), isFalse);
    });
  });
}
