import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barbs_bedtime_stories/core/constants/firestore_paths.dart';
import 'package:barbs_bedtime_stories/data/models/user_preferences.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserPreferences?> getUserPreferences(String userId) async {
    try {
      final doc = await _firestore.collection(FirestorePaths.users).doc(userId).get();
      if (doc.exists) {
        return UserPreferences.fromFirestore(doc);
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveUserPreferences(UserPreferences prefs) async {
    try {
      await _firestore
          .collection(FirestorePaths.users)
          .doc(prefs.id)
          .set(prefs.toFirestore(), SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> toggleFavorite(String userId, String storyId) async {
    try {
      final docRef = _firestore.collection(FirestorePaths.users).doc(userId);
      final doc = await docRef.get();
      
      if (doc.exists) {
        final prefs = UserPreferences.fromFirestore(doc);
        final isFavorite = prefs.favorites.contains(storyId);
        
        if (isFavorite) {
          await docRef.update({
            'favorites': FieldValue.arrayRemove([storyId]),
          });
        } else {
          await docRef.update({
            'favorites': FieldValue.arrayUnion([storyId]),
          });
        }
      } else {
        // Create new user preferences if they don't exist
        await docRef.set({
          'favorites': [storyId],
          'recentlyPlayed': [],
          'sleepTimerMinutes': 30,
          'autoPlay': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}
  }

  Future<void> addRecentPlay(String userId, String storyId, Duration progress) async {
    try {
      final docRef = _firestore.collection(FirestorePaths.users).doc(userId);
      final doc = await docRef.get();
      
      final newPlay = RecentPlay(
        storyId: storyId,
        timestamp: DateTime.now(),
        progress: progress,
      );
      
      if (doc.exists) {
        final prefs = UserPreferences.fromFirestore(doc);
        // Remove older play of the same story
        final existingPlays = prefs.recentlyPlayed
            .where((p) => p.storyId != storyId)
            .toList();
            
        existingPlays.insert(0, newPlay); // Add to beginning
        
        // Keep only top 20 recent plays
        if (existingPlays.length > 20) {
          existingPlays.removeRange(20, existingPlays.length);
        }
        
        await docRef.update({
          'recentlyPlayed': existingPlays.map((e) => e.toMap()).toList(),
        });
      } else {
        await docRef.set({
          'favorites': [],
          'recentlyPlayed': [newPlay.toMap()],
          'sleepTimerMinutes': 30,
          'autoPlay': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}
  }
}
