import 'package:cloud_firestore/cloud_firestore.dart';

class RecentPlay {
  final String storyId;
  final DateTime timestamp;
  final Duration progress;

  RecentPlay({
    required this.storyId,
    required this.timestamp,
    required this.progress,
  });

  factory RecentPlay.fromMap(Map<String, dynamic> data) {
    return RecentPlay(
      storyId: (data['storyId'] ?? '').toString(),
      timestamp: (data['timestamp'] is Timestamp)
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      progress: Duration(
        seconds: (data['progressSeconds'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'storyId': storyId,
      'timestamp': Timestamp.fromDate(timestamp),
      'progressSeconds': progress.inSeconds,
    };
  }
}

class UserPreferences {
  final String id;
  final List<String> favorites;
  final List<RecentPlay> recentlyPlayed;
  final int sleepTimerMinutes;
  final bool autoPlay;
  final DateTime createdAt;

  UserPreferences({
    required this.id,
    required this.favorites,
    required this.recentlyPlayed,
    required this.sleepTimerMinutes,
    required this.autoPlay,
    required this.createdAt,
  });

  factory UserPreferences.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawRecent = data['recentlyPlayed'];
    final List<RecentPlay> parsedRecent = [];
    if (rawRecent is List) {
      for (final item in rawRecent) {
        if (item is Map) {
          try {
            parsedRecent.add(RecentPlay.fromMap(Map<String, dynamic>.from(item)));
          } catch (_) {}
        }
      }
    }

    final rawFavs = data['favorites'];
    final parsedFavs = (rawFavs is List)
        ? rawFavs.map((e) => e.toString()).toList()
        : <String>[];

    return UserPreferences(
      id: doc.id,
      favorites: parsedFavs,
      recentlyPlayed: parsedRecent,
      sleepTimerMinutes: (data['sleepTimerMinutes'] as num?)?.toInt() ?? 30,
      autoPlay: data['autoPlay'] == true,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'favorites': favorites,
      'recentlyPlayed': recentlyPlayed.map((e) => e.toMap()).toList(),
      'sleepTimerMinutes': sleepTimerMinutes,
      'autoPlay': autoPlay,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
