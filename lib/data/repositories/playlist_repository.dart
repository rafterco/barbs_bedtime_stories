import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barbs_bedtime_stories/core/constants/firestore_paths.dart';
import 'package:barbs_bedtime_stories/data/models/playlist.dart';
import 'package:barbs_bedtime_stories/data/models/story.dart';
import 'package:rxdart/rxdart.dart';

class PlaylistRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Playlist>> getPublishedPlaylists() {
    // Combine both 'playlist' (singular legacy) and 'playlists' (plural new)
    final legacyStream = _firestore.collection('playlist').snapshots().map(
          (snap) => snap.docs.map((doc) {
            try {
              return Playlist.fromFirestore(doc);
            } catch (e) {
              return null;
            }
          }).whereType<Playlist>().toList(),
        );
        
    final newStream = _firestore.collection('playlists').snapshots().map(
          (snap) => snap.docs.map((doc) {
            try {
              return Playlist.fromFirestore(doc);
            } catch (e) {
              return null;
            }
          }).whereType<Playlist>().toList(),
        );

    return Rx.combineLatest2<List<Playlist>, List<Playlist>, List<Playlist>>(
      legacyStream,
      newStream,
      (legacyList, newList) {
        final Map<String, Playlist> map = {};
        for (final p in legacyList) {
          if (p.isPublished) map[p.id] = p;
        }
        for (final p in newList) {
          if (p.isPublished) map[p.id] = p;
        }
        final list = map.values.toList();
        list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        return list;
      },
    );
  }

  Future<Playlist?> getPlaylistById(String id) async {
    if (id.trim().isEmpty) return null;
    // Try 'playlists' first, fallback to 'playlist'
    var doc = await _firestore.collection('playlists').doc(id).get();
    if (!doc.exists) {
      doc = await _firestore.collection('playlist').doc(id).get();
    }
    if (doc.exists) {
      try {
        return Playlist.fromFirestore(doc);
      } catch (_) {}
    }
    return null;
  }

  Future<List<Story>> getPlaylistStories(Playlist playlist) async {
    if (playlist.storyIds.isEmpty) return [];

    // Fetch all stories from both stories and posts collections to match by ID or Title
    final storiesSnap = await _firestore.collection(FirestorePaths.stories).get();
    final postsSnap = await _firestore.collection('posts').get();

    final Map<String, Story> storyMap = {};
    for (final doc in postsSnap.docs) {
      try {
        final s = Story.fromFirestore(doc);
        storyMap[s.id] = s;
      } catch (_) {}
    }
    for (final doc in storiesSnap.docs) {
      try {
        final s = Story.fromFirestore(doc);
        storyMap[s.id] = s;
      } catch (_) {}
    }
    final allStories = storyMap.values.toList();

    final List<Story> matched = [];
    for (final identifier in playlist.storyIds) {
      final found = allStories.firstWhere(
        (s) => s.id == identifier || s.title.trim().toLowerCase() == identifier.trim().toLowerCase(),
        orElse: () => Story(
          id: '',
          title: identifier,
          description: '',
          narrator: 'Barbara',
          duration: 0,
          category: '',
          tags: [],
          audioUrl: '',
          coverImageUrl: playlist.coverImageUrl,
          isFeatured: false,
          isPublished: true,
          playCount: 0,
          sortOrder: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      if (found.id.isNotEmpty) {
        matched.add(found);
      }
    }

    return matched;
  }
}
