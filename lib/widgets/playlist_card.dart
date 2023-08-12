import 'package:barbs_bedtime_stories/models/story_model.dart';
import 'package:barbs_bedtime_stories/screens/playlist_screen.dart';
import 'package:flutter/material.dart';

import '../global/globals.dart';
import '../models/playlist_model.dart';
import '../screens/story_screen.dart';

import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class PlaylistCard extends StatelessWidget {
  const PlaylistCard({
    Key? key,
    required this.playlist,
  }) : super(key: key);

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    final firebase_storage.FirebaseStorage storage = firebase_storage.FirebaseStorage.instance;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PlaylistScreen(
                    playlist: playlist,
                  )),
        );
      },
      child: Container(
        height: 75,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade800.withOpacity(0.6),
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3), // Shadow color
              spreadRadius: 3, // Spread radius
              blurRadius: 1, // Blur radius
              offset: const Offset(0, 1), // Offset in the x and y direction
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 3, 0, 3),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15.0),
                child: FutureBuilder<String>(
                  future: storage.refFromURL(playlist.imageUrl).getDownloadURL(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      String imageUrl = snapshot.data.toString();
                      return Image.network(imageUrl);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    playlist.title,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${playlist.stories.length} stories',
                    maxLines: 2,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                Set<Story> storiesSet =
                    Global.playListStoriesToStory[playlist.title] ?? <Story>{};
                List<Story> storiesList = storiesSet.toList();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => StoryScreen(storiesList)),
                );
              },
              icon: const Icon(
                Icons.play_circle,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
