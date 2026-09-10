import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barbs_bedtime_stories/core/constants/firestore_paths.dart';
import 'package:barbs_bedtime_stories/data/models/story.dart';
import 'package:rxdart/rxdart.dart';

class StoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Story>> _getAllRawStoriesStream() {
    final storiesStream = _firestore
        .collection(FirestorePaths.stories)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              try {
                return Story.fromFirestore(doc);
              } catch (e) {
                debugPrint('Error parsing story ${doc.id}: $e');
              }
            },
          ).whereType<Story>().toList(),
    );

    final postsStream = _firestore
        .collection('posts')
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) {
            try {
              return Story.fromFirestore(doc);
            } catch (e) {
              debugPrint('Error parsing post ${doc.id}: $e');
              return null;
            }
          }).whereType<Story>().toList(),
        );

    return Rx.combineLatest2<List<Story>, List<Story>, List<Story>>(
      storiesStream,
      postsStream,
      (storiesList, postsList) {
        final Map<String, Story> map = {};
        for (final s in postsList) {
          map[s.id] = s;
        }
        for (final s in storiesList) {
          map[s.id] = s;
        }
        return map.values.toList();
      },
    );
  }

  Stream<List<Story>> getPublishedStories() {
    return _getAllRawStoriesStream().map((stories) {
      final published = stories.where((s) => s.isPublished).toList();
      published.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return published;
    });
  }

  Stream<List<Story>> getFeaturedStories() {
    return _getAllRawStoriesStream().map((stories) {
      final featured = stories.where((s) => s.isPublished && s.isFeatured).toList();
      featured.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return featured;
    });
  }

  Stream<List<Story>> getStoriesByCategory(String category) {
    return _getAllRawStoriesStream().map((stories) {
      final filtered = stories.where((story) =>
          story.isPublished &&
          (category.isEmpty || story.category.toLowerCase() == category.toLowerCase()),).toList();
      filtered.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return filtered;
    });
  }

  Future<Story?> getStoryById(String id) async {
    if (id.trim().isEmpty) return null;
    try {
      var doc = await _firestore.collection(FirestorePaths.stories).doc(id).get();
      if (!doc.exists) {
        doc = await _firestore.collection('posts').doc(id).get();
      }
      if (doc.exists) {
        return Story.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Error getting story by id from Firestore: $e');
    }
    return null;
  }

  Stream<List<Story>> searchStories(String query) {
    final lowerQuery = query.toLowerCase();
    return getPublishedStories().map((stories) {
      if (query.isEmpty) return stories;
      return stories.where((story) {
        return story.title.toLowerCase().contains(lowerQuery) ||
            story.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
      }).toList();
    });
  }

  Future<void> incrementPlayCount(String storyId) async {
    if (storyId.trim().isEmpty) return;
    try {
      await _firestore.collection(FirestorePaths.stories).doc(storyId).update({
        'playCount': FieldValue.increment(1),
      });
    } catch (_) {
      try {
        await _firestore.collection('posts').doc(storyId).update({
          'playCount': FieldValue.increment(1),
        });
      } catch (_) {}
    }
  }
}
