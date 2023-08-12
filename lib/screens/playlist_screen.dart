import 'package:barbs_bedtime_stories/screens/story_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../global/globals.dart';
import '../models/playlist_model.dart';
import '../models/story_model.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

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
                _PlayOrShuffleSwitch(playlist, playList_: playlist,),
                const SizedBox(height: 10),
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

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(15, 0, 0, 20),
                        child: Column(
                          children: [
                            playlist.stories.contains(story) ? const SizedBox(height: 5) : const SizedBox(height: 0),
                            playlist.stories.contains(story) ? ListTile(
                              title: Text(
                                data.docs[index]['title'],
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .copyWith(fontWeight: FontWeight.bold),

                              ),
                              subtitle: Text(data.docs[index]['description']),
                            ) : const SizedBox(height: 0,),
                          ],
                        ),
                      );
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
  const _PlayOrShuffleSwitch(Playlist playlist, {
    Key? key, required this.playList_,
  }) : super(key: key);

  final Playlist playList_;

  @override
  State<_PlayOrShuffleSwitch> createState() => _PlayOrShuffleSwitchState(playList_);
}

class _PlayOrShuffleSwitchState extends State<_PlayOrShuffleSwitch> {
  bool isPlay = true;

  List<Widget> fruits = <Widget>[
    const Text('Play'),
    const Text('Shuffle')
  ];

  final List<bool> _selected = <bool>[true, false];

  _PlayOrShuffleSwitchState(this.playList_);

  final Playlist playList_;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    Global.getStories();

    return GestureDetector(
      onTap: () {
        setState(() {
          isPlay = !isPlay;
        });
      },
      child: Container(
        height: 50,
        width: width,

        child: Stack(
          children: [
            Center(
              child: ToggleButtons(
                direction: Axis.horizontal,
                onPressed: (int index) {
                  setState(() {
                    List<Story> storiesList = [];
                    for (int i = 0; i < _selected.length; i++) {
                      _selected[i] = i == index;

                      Set<Story> storiesSet = Global.playListStoriesToStory[playList_.title] ?? <Story>{};
                      storiesList = storiesSet.toList();

                    }
                    if (storiesList.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>
                            StoryScreen(storiesList)),
                      );
                    }

                  });
                },
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                //Colors.deepPurple.shade600,
                selectedBorderColor: Colors.black,
                selectedColor: Colors.white,
                fillColor: Colors.deepPurple.shade800,
                color: Colors.white38,
                textStyle: TextStyle(fontWeight: FontWeight.bold),
                constraints: const BoxConstraints(
                  minHeight: 40.0,
                  minWidth: 80.0,
                ),
                isSelected: _selected,
                children: fruits,
              ),
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
    final firebase_storage.FirebaseStorage storage = firebase_storage.FirebaseStorage.instance;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(15.0),
          child: FutureBuilder<String>(
            future: storage.refFromURL(playlist.imageUrl).getDownloadURL(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                String imageUrl = snapshot.data.toString();
                return Image.network(
                  imageUrl,
                  height: MediaQuery.of(context).size.height * 0.30,
                  width: MediaQuery.of(context).size.height * 0.30,
                  fit: BoxFit.cover,
                );
              }
            },
          )
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
