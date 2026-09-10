import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

import 'package:barbs_bedtime_stories/data/models/story.dart';

/// Manages offline downloads of story audio files.
///
/// Uses [flutter_cache_manager] for managed file caching with a custom
/// cache key per story. Provides progress tracking via [ValueNotifier].
class DownloadService {
  DownloadService._();
  static final DownloadService instance = DownloadService._();

  /// Custom cache manager with a 14-day TTL and 200MB effective cap (~50 stories).
  static final _cacheManager = CacheManager(
    Config(
      'bedtime_stories_audio',
      stalePeriod: const Duration(days: 14),
      maxNrOfCacheObjects: 50,
    ),
  );

  /// Set of story IDs currently being downloaded.
  final ValueNotifier<Set<String>> activeDownloads = ValueNotifier({});

  /// Set of story IDs that are available offline.
  final ValueNotifier<Set<String>> downloadedStories = ValueNotifier({});

  /// Initialize — scan existing cache for downloaded stories.
  Future<void> init() async {
    // We can't enumerate the cache directly, so we rely on
    // checking individual stories when the user opens the app.
    // The downloadedStories set will be populated as stories are checked.
  }

  /// Download a story's audio for offline use.
  Future<void> downloadStory(Story story) async {
    if (activeDownloads.value.contains(story.id)) return;

    final targetUrl = resolveStorageUrl(story.audioUrl);
    if (!targetUrl.startsWith('http://') && !targetUrl.startsWith('https://')) {
      debugPrint('Invalid audio URL for download: $targetUrl');
      return;
    }

    // Add to active downloads
    activeDownloads.value = {...activeDownloads.value, story.id};

    try {
      await _cacheManager.downloadFile(
        targetUrl,
        key: 'story_${story.id}',
      );

      // Mark as downloaded
      downloadedStories.value = {...downloadedStories.value, story.id};
    } catch (e) {
      debugPrint('Download failed for ${story.title}: $e');
    } finally {
      // Remove from active downloads
      final updated = {...activeDownloads.value};
      updated.remove(story.id);
      activeDownloads.value = updated;
    }
  }

  /// Check if a story is available offline.
  Future<bool> isDownloaded(String storyId) async {
    try {
      final fileInfo = await _cacheManager.getFileFromCache('story_$storyId');
      final isAvailable = fileInfo != null;
      if (isAvailable) {
        downloadedStories.value = {...downloadedStories.value, storyId};
      }
      return isAvailable;
    } catch (_) {
      return false;
    }
  }

  /// Get the local file path for a downloaded story.
  /// Returns null if not downloaded.
  Future<String?> getLocalPath(String storyId) async {
    try {
      final fileInfo = await _cacheManager.getFileFromCache('story_$storyId');
      return fileInfo?.file.path;
    } catch (_) {
      return null;
    }
  }

  /// Silently cache a story's audio in the background after first stream.
  /// This is fire-and-forget — errors are swallowed so playback is never blocked.
  void cacheInBackground(String storyId, String url) {
    if (!url.startsWith('http://') && !url.startsWith('https://')) return;

    // Don't re-cache if already downloading or cached
    if (activeDownloads.value.contains(storyId)) return;

    () async {
      try {
        final existing = await _cacheManager.getFileFromCache('story_$storyId');
        if (existing != null) return; // Already cached

        debugPrint('Auto-caching audio for story $storyId...');
        await _cacheManager.downloadFile(url, key: 'story_$storyId');
        downloadedStories.value = {...downloadedStories.value, storyId};
        debugPrint('Auto-cached audio for story $storyId ✓');
      } catch (e) {
        debugPrint('Auto-cache failed for story $storyId (non-fatal): $e');
      }
    }();
  }

  /// Refresh the cache TTL for a story so it doesn't expire while still
  /// being actively played. Fire-and-forget — won't block playback.
  void refreshCacheTTL(String storyId, String url) {
    if (!url.startsWith('http://') && !url.startsWith('https://')) return;

    () async {
      try {
        // Re-downloading via cache manager resets the stalePeriod timestamp
        await _cacheManager.downloadFile(url, key: 'story_$storyId');
      } catch (e) {
        debugPrint('TTL refresh failed for story $storyId (non-fatal): $e');
      }
    }();
  }

  /// Remove a downloaded story.
  Future<void> removeDownload(String storyId) async {
    await _cacheManager.removeFile('story_$storyId');
    final updated = {...downloadedStories.value};
    updated.remove(storyId);
    downloadedStories.value = updated;
  }

  /// Get total size of downloaded files.
  Future<int> getTotalCacheSize() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final bedtimeDir = Directory('${cacheDir.path}/bedtime_stories_audio');
      if (!bedtimeDir.existsSync()) return 0;
      int totalSize = 0;
      await for (final entity in bedtimeDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (_) {
      return 0;
    }
  }

  /// Clear all downloaded stories.
  Future<void> clearAll() async {
    await _cacheManager.emptyCache();
    downloadedStories.value = {};
  }
}
