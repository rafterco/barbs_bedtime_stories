import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper to convert gs:// storage URIs and legacy asset paths to public HTTP URLs
String resolveStorageUrl(dynamic rawUrl) {
  if (rawUrl == null) return '';
  final str = rawUrl.toString().trim();
  if (str.isEmpty) return '';
  if (str.startsWith('http://') || str.startsWith('https://')) return str;

  const bucket = 'bedtime-stories-app-ccb9d.appspot.com';

  if (str.startsWith('gs://')) {
    final noGs = str.substring(5); // e.g. "bucket.appspot.com/path/to/file.jpg"
    final firstSlash = noGs.indexOf('/');
    if (firstSlash != -1) {
      final b = noGs.substring(0, firstSlash);
      final path = noGs.substring(firstSlash + 1);
      return 'https://firebasestorage.googleapis.com/v0/b/$b/o/${Uri.encodeComponent(path)}?alt=media';
    }
  }

  // Known legacy assets mapping
  const legacyMap = <String, String>{
    'assets/images/TheToadAndTheButterfly.jpg': 'covers/toad_and_butterfly.jpg',
    'assets/images/thetoadandthebutterfly.jpg': 'covers/toad_and_butterfly.jpg',
    'assets/images/ADayClosesInTheWoods.jpg': 'stories/Playlists/SunsetInWoods.png',
    'assets/images/TheKitchenSink.jpg': 'covers/sing.jpg',
    'assets/images/TheSockDrawer.jpg': 'covers/socks1.jpg',
    'assets/music/pray.mp3': 'stories/pray.mp3',
    'assets/music/TheToadAndTheButterfly.mp3': 'stories/TheToadAndTheButterfly.mp3',
    'assets/music/ADayClosesInTheWoods.mp3': 'stories/ADayClosesInTheWoods.mp3',
    'assets/music/TheKitchenSink.mp3': 'stories/TheKitchenSink.mp3',
    'assets/music/TheSockDrawer.mp3': 'stories/TheSockDrawer.mp3',
  };

  final mapped = legacyMap[str];
  if (mapped != null) {
    return 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/${Uri.encodeComponent(mapped)}?alt=media';
  }

  if (str.startsWith('assets/music/')) {
    final fileName = str.replaceFirst('assets/music/', '');
    return 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/${Uri.encodeComponent("stories/$fileName")}?alt=media';
  }

  if (str.startsWith('assets/images/')) {
    final fileName = str.replaceFirst('assets/images/', '');
    return 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/${Uri.encodeComponent("covers/$fileName")}?alt=media';
  }

  if (str.startsWith('videos/') || str.startsWith('covers/') || str.startsWith('stories/')) {
    return 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/${Uri.encodeComponent(str)}?alt=media';
  }

  if (str.endsWith('.mp3') ||
      str.endsWith('.m4a') ||
      str.endsWith('.mp4') ||
      str.endsWith('.mov') ||
      str.endsWith('.m4v') ||
      str.endsWith('.webm')) {
    return 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/${Uri.encodeComponent("stories/$str")}?alt=media';
  }

  if (str.endsWith('.jpg') || str.endsWith('.png') || str.endsWith('.jpeg')) {
    return 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/${Uri.encodeComponent("covers/$str")}?alt=media';
  }

  return str;
}

class Story {
  final String id;
  final String title;
  final String description;
  final String narrator;
  final int duration; // seconds
  final String category;
  final List<String> tags;
  final String audioUrl;
  final String coverImageUrl;
  final String? videoUrl;
  final bool isFeatured;
  final bool isPublished;
  final int playCount;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  Story({
    required this.id,
    required this.title,
    required this.description,
    required this.narrator,
    required this.duration,
    required this.category,
    required this.tags,
    required this.audioUrl,
    required this.coverImageUrl,
    this.videoUrl,
    required this.isFeatured,
    required this.isPublished,
    required this.playCount,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Checks whether a given URL points to a video file
  static bool isVideoUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final clean = url.trim().toLowerCase();
    final pathOnly = clean.split('?').first;
    return pathOnly.endsWith('.mp4') ||
        pathOnly.endsWith('.mov') ||
        pathOnly.endsWith('.m4v') ||
        pathOnly.endsWith('.webm') ||
        pathOnly.endsWith('.mkv') ||
        pathOnly.endsWith('.avi') ||
        clean.contains('.mp4?') ||
        clean.contains('.mov?') ||
        clean.contains('.m4v?') ||
        clean.contains('.webm?') ||
        clean.contains('.mkv?') ||
        clean.contains('videos%2f') ||
        clean.contains('/videos/') ||
        clean.contains('video%2f') ||
        clean.contains('/video/');
  }

  /// Whether this story contains a playable video
  bool get isVideo =>
      (videoUrl != null && videoUrl!.trim().isNotEmpty) ||
      isVideoUrl(audioUrl);

  /// Resolves the effective video URL (falling back to audioUrl if that contains the video)
  String get effectiveVideoUrl {
    if (videoUrl != null && videoUrl!.trim().isNotEmpty) {
      return videoUrl!;
    }
    if (isVideoUrl(audioUrl)) {
      return audioUrl;
    }
    return '';
  }

  Story copyWith({
    String? id,
    String? title,
    String? description,
    String? narrator,
    int? duration,
    String? category,
    List<String>? tags,
    String? audioUrl,
    String? coverImageUrl,
    String? videoUrl,
    bool? isFeatured,
    bool? isPublished,
    int? playCount,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Story(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      narrator: narrator ?? this.narrator,
      duration: duration ?? this.duration,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      audioUrl: audioUrl ?? this.audioUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      isFeatured: isFeatured ?? this.isFeatured,
      isPublished: isPublished ?? this.isPublished,
      playCount: playCount ?? this.playCount,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Story.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final rawAudio = data['audioUrl'] ?? data['url'] ?? data['cloudUrl'] ?? data['audio'] ?? data['fileUrl'];
    final rawCover = data['coverImageUrl'] ?? data['imageUrl'] ?? data['coverUrl'] ?? data['cover'] ?? data['image'];
    final rawVideo = data['videoUrl'] ?? data['video'];

    final rawTags = data['tags'];
    final parsedTags = (rawTags is List)
        ? rawTags.map((e) => e.toString()).toList()
        : <String>[];

    final resolvedAudio = resolveStorageUrl(rawAudio);
    String? resolvedVideo = rawVideo != null ? resolveStorageUrl(rawVideo) : null;
    if ((resolvedVideo == null || resolvedVideo.isEmpty) && isVideoUrl(resolvedAudio)) {
      resolvedVideo = resolvedAudio;
    }

    return Story(
      id: doc.id,
      title: (data['title'] ?? data['name'] ?? 'Bedtime Story').toString(),
      description: (data['description'] ?? '').toString(),
      narrator: (data['narrator'] ?? 'Barbara').toString(),
      duration: (data['duration'] as num?)?.toInt() ??
          ((data['durationSeconds'] as num?)?.toInt() ?? 0),
      category: (data['category'] ?? data['categoryId'] ?? '').toString(),
      tags: parsedTags,
      audioUrl: resolvedAudio,
      coverImageUrl: resolveStorageUrl(rawCover),
      videoUrl: resolvedVideo,
      isFeatured: data['isFeatured'] == true,
      isPublished: data['isPublished'] != false,
      playCount: (data['playCount'] as num?)?.toInt() ?? 0,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'narrator': narrator,
      'duration': duration,
      'category': category,
      'tags': tags,
      'audioUrl': audioUrl,
      'coverImageUrl': coverImageUrl,
      'videoUrl': videoUrl,
      'isFeatured': isFeatured,
      'isPublished': isPublished,
      'playCount': playCount,
      'sortOrder': sortOrder,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  @override
  String toString() => 'Story(id: $id, title: $title)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Story &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title;

  @override
  int get hashCode => id.hashCode ^ title.hashCode;
}
