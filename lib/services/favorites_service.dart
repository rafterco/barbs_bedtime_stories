import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages user favorite stories with instant local persistence and reactive ValueNotifier.
class FavoritesService {
  FavoritesService._();
  static final FavoritesService instance = FavoritesService._();

  static const String _storageKey = 'favorite_story_ids';
  static const String _playlistStorageKey = 'favorite_playlist_ids';

  final ValueNotifier<Set<String>> favoriteIds = ValueNotifier<Set<String>>({});
  final ValueNotifier<Set<String>> favoritePlaylistIds = ValueNotifier<Set<String>>({});
  bool _initialized = false;

  /// Initialize and load saved favorites from local storage.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_storageKey) ?? [];
      favoriteIds.value = list.toSet();
      final playlistList = prefs.getStringList(_playlistStorageKey) ?? [];
      favoritePlaylistIds.value = playlistList.toSet();
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  /// Check if a story is favorited.
  bool isFavorite(String storyId) {
    return favoriteIds.value.contains(storyId);
  }

  /// Toggle favorite status for a story. Returns new favorite state.
  Future<bool> toggleFavorite(String storyId) async {
    await init();
    final current = Set<String>.from(favoriteIds.value);
    final willBeFavorite = !current.contains(storyId);
    
    if (willBeFavorite) {
      current.add(storyId);
    } else {
      current.remove(storyId);
    }
    
    favoriteIds.value = current;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, current.toList());
    } catch (e) {
      debugPrint('Error persisting favorite: $e');
    }

    return willBeFavorite;
  }

  /// Explicitly remove a story favorite.
  Future<void> removeFavorite(String storyId) async {
    await init();
    if (!favoriteIds.value.contains(storyId)) return;
    final current = Set<String>.from(favoriteIds.value);
    current.remove(storyId);
    favoriteIds.value = current;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, current.toList());
    } catch (e) {
      debugPrint('Error removing favorite: $e');
    }
  }

  /// Check if a playlist is favorited.
  bool isPlaylistFavorite(String playlistId) {
    return favoritePlaylistIds.value.contains(playlistId);
  }

  /// Toggle favorite status for a playlist. Returns new favorite state.
  Future<bool> togglePlaylistFavorite(String playlistId) async {
    await init();
    final current = Set<String>.from(favoritePlaylistIds.value);
    final willBeFavorite = !current.contains(playlistId);
    
    if (willBeFavorite) {
      current.add(playlistId);
    } else {
      current.remove(playlistId);
    }
    
    favoritePlaylistIds.value = current;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_playlistStorageKey, current.toList());
    } catch (e) {
      debugPrint('Error persisting playlist favorite: $e');
    }

    return willBeFavorite;
  }

  /// Explicitly remove a playlist favorite.
  Future<void> removePlaylistFavorite(String playlistId) async {
    await init();
    if (!favoritePlaylistIds.value.contains(playlistId)) return;
    final current = Set<String>.from(favoritePlaylistIds.value);
    current.remove(playlistId);
    favoritePlaylistIds.value = current;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_playlistStorageKey, current.toList());
    } catch (e) {
      debugPrint('Error removing playlist favorite: $e');
    }
  }
}
