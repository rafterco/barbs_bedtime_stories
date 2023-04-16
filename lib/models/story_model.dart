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

/*static List<Story> stories = [
    Story(
      title: 'Glass',
      description: 'Glass',
      url: 'assets/music/glass.mp3',
      coverUrl: 'assets/images/glass.jpg',
    ),
    Story(
      title: 'Illusions',
      description: 'Illusions',
      url: 'assets/music/illusions.mp3',
      coverUrl: 'assets/images/illusions.jpg',
    ),
    Story(
      title: 'Pray',
      description: 'Pray',
      url: 'assets/music/pray.mp3',
      coverUrl: 'assets/images/pray.jpg',
    )
  ];*/
}
