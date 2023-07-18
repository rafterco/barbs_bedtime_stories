import 'story_model.dart';

class Playlist {
  final String title;
  final List<String> stories;
  final String imageUrl;

  Playlist({
    required this.title,
    required this.stories,
    required this.imageUrl,
  });

  @override
  String toString() {
    return 'Playlist{title: $title, stories: $stories, imageUrl: $imageUrl}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Playlist &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          stories == other.stories &&
          imageUrl == other.imageUrl;

  @override
  int get hashCode => title.hashCode ^ stories.hashCode ^ imageUrl.hashCode;
}
