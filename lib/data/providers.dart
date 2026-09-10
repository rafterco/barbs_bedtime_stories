import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barbs_bedtime_stories/data/repositories/story_repository.dart';
import 'package:barbs_bedtime_stories/data/repositories/playlist_repository.dart';
import 'package:barbs_bedtime_stories/data/repositories/config_repository.dart';
import 'package:barbs_bedtime_stories/data/repositories/user_repository.dart';
import 'package:barbs_bedtime_stories/data/models/category.dart';
import 'package:barbs_bedtime_stories/core/constants/firestore_paths.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final storyRepositoryProvider = Provider((ref) => StoryRepository());
final playlistRepositoryProvider = Provider((ref) => PlaylistRepository());
final configRepositoryProvider = Provider((ref) => ConfigRepository());
final userRepositoryProvider = Provider((ref) => UserRepository());

final publishedStoriesProvider = StreamProvider((ref) {
  return ref.watch(storyRepositoryProvider).getPublishedStories();
});

final featuredStoriesProvider = StreamProvider((ref) {
  return ref.watch(storyRepositoryProvider).getFeaturedStories();
});

final publishedPlaylistsProvider = StreamProvider((ref) {
  return ref.watch(playlistRepositoryProvider).getPublishedPlaylists();
});

final appConfigProvider = StreamProvider((ref) {
  return ref.watch(configRepositoryProvider).getAppConfig();
});

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return FirebaseFirestore.instance
      .collection(FirestorePaths.categories)
      .orderBy('sortOrder')
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList(),);
});
