import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barbs_bedtime_stories/data/models/story.dart';

class Playlist {
  final String id;
  final String title;
  final String description;
  final String coverImageUrl;
  final List<String> storyIds; // Can contain IDs or story titles from legacy data
  final bool isPublished;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  Playlist({
    required this.id,
    required this.title,
    required this.description,
    required this.coverImageUrl,
    required this.storyIds,
    required this.isPublished,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  Playlist copyWith({
    String? id,
    String? title,
    String? description,
    String? coverImageUrl,
    List<String>? storyIds,
    bool? isPublished,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      storyIds: storyIds ?? this.storyIds,
      isPublished: isPublished ?? this.isPublished,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Playlist.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawCover = data['coverImageUrl'] ?? data['imageUrl'] ?? data['image'];

    final rawStories = data['storyIds'] ?? data['stories'] ?? data['story_ids'] ?? [];
    final parsedStoryIds = <String>[];
    if (rawStories is List) {
      for (final item in rawStories) {
        if (item is String && item.trim().isNotEmpty) {
          parsedStoryIds.add(item.trim());
        } else if (item is Map) {
          final id = item['id'] ?? item['storyId'] ?? item['title'] ?? item['name'];
          if (id != null && id.toString().trim().isNotEmpty) {
            parsedStoryIds.add(id.toString().trim());
          }
        }
      }
    }

    return Playlist(
      id: doc.id,
      title: (data['title'] ?? data['name'] ?? 'Bedtime Playlist').toString(),
      description: (data['description'] ?? '').toString(),
      coverImageUrl: resolveStorageUrl(rawCover),
      storyIds: parsedStoryIds,
      isPublished: data['isPublished'] != false,
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
      'coverImageUrl': coverImageUrl,
      'storyIds': storyIds,
      'isPublished': isPublished,
      'sortOrder': sortOrder,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Playlist &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
