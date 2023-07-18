import 'package:barbs_bedtime_stories/models/firebase_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Story {
  final String title;
  final String description;
  final String url;
  final String coverUrl;
  final FirebaseImage firebaseImage = FirebaseImage(storagePath: 'stories');

  Story({
    required this.title,
    required this.description,
    required this.url,
    required this.coverUrl,
  });


  @override
  String toString() {
    return 'Story{title: $title, description: $description, url: $url, coverUrl: $coverUrl, firebaseImage: $firebaseImage}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Story &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          description == other.description &&
          url == other.url &&
          coverUrl == other.coverUrl;

  @override
  int get hashCode =>
      title.hashCode ^
      description.hashCode ^
      url.hashCode ^
      coverUrl.hashCode;
}
