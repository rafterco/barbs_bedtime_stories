import 'package:barbs_bedtime_stories/widgets/story_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/playlist_model.dart';

class PlaylistScreen extends StatelessWidget {
  PlaylistScreen({
    Key? key,
    required this.playlist,
  }) : super(key: key);

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.deepPurple.shade800.withOpacity(0.8),
            Colors.deepPurple.shade200.withOpacity(0.8),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Recommended Playlist'),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _PlaylistInformation(playlist: playlist),
                const SizedBox(height: 30),
                const _PlayOrShuffleSwitch(),
                _PlaylistStories(playlist: playlist),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaylistStories extends StatelessWidget {
  const _PlaylistStories({
    Key? key,
    required this.playlist,
  }) : super(key: key);

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> storiesStream =
    FirebaseFirestore.instance.collection('stories').snapshots();

    print('The stories I need to display');
    for (var i = 0; i < playlist.stories.length; i++) {
      print(playlist.stories[i]);
    }
    print('\n');

    return SizedBox(
      height: 280,
      child: Column(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: storiesStream,
            builder: (BuildContext context,
                AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) {
                return const Text('error downloading Stories');
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text('downloading data');
              }

              final data = snapshot.requireData;

              bool isShuffle = true;
              if (isShuffle) {
                bool isShuffle = false;
                //build the listTiles here
                playlist.stories.shuffle();

              }
              return Expanded(
                child: ListView.builder(
                  //shrinkWrap: true,
                  //physics: const NeverScrollableScrollPhysics(),
                  itemCount: data.size,
                  itemBuilder: (context, index) {
                    String story = data.docs[index]['title'];
                    print('the story I have  $story');

                    if (playlist.stories.contains(story)) {
                      return ListTile(
                        leading: Text(
                          '${index + 1}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        title: Text(
                          data.docs[index]['title'],
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(data.docs[index]['description']),
                        // trailing: IconButton(
                        //   icon: const Icon(
                        //       Icons.more_vert,
                        //       color: Colors.white,
                        //   ),
                        //   // the method which is called
                        //   // when button is pressed
                        //   onPressed: () {
                        //     print('pressed');
                        //   },
                        // ),
                      );
                    }
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

}

class _PlayOrShuffleSwitch extends StatefulWidget {
  const _PlayOrShuffleSwitch({
    Key? key,
  }) : super(key: key);

  @override
  State<_PlayOrShuffleSwitch> createState() => _PlayOrShuffleSwitchState();
}

class _PlayOrShuffleSwitchState extends State<_PlayOrShuffleSwitch> {
  bool isPlay = true;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () {
        print('raf');
        setState(() {
          isPlay = !isPlay;
        });
      },
      child: Container(
        height: 50,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              left: isPlay ? 0 : width * 0.45,
              child: Container(
                height: 50,
                width: width * 0.45,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade400,
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            Row(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child: Text(
                        'Play',
                        style: TextStyle(
                          color: isPlay ? Colors.white : Colors.deepPurple,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.play_circle,
                      color: isPlay ? Colors.white : Colors.deepPurple,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child: Text(
                        'Shuffle',
                        style: TextStyle(
                          color: isPlay ? Colors.deepPurple : Colors.white,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.shuffle,
                      color: isPlay ? Colors.deepPurple : Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistInformation extends StatelessWidget {
  const _PlaylistInformation({
    Key? key,
    required this.playlist,
  }) : super(key: key);

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(15.0),
          child: Image.network(
            playlist.imageUrl,
            height: MediaQuery.of(context).size.height * 0.3,
            width: MediaQuery.of(context).size.height * 0.3,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 30),
        Text(
          playlist.title,
          style: Theme.of(context)
              .textTheme
              .headlineSmall!
              .copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
