import 'package:barbs_bedtime_stories/screens/story_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../global/globals.dart';
import '../models/playlist_model.dart';
import '../models/story_model.dart';

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
                    // The button that is tapped is set to true, and the others to false.
                    for (int i = 0; i < _selected.length; i++) {
                      _selected[i] = i == index;
                      //isPlaylist = _selected[0] == true;

                      Set<Story> storiesSet = Global.playListStoriesToStory[playList_.title] ?? <Story>{};
                      List<Story> storiesList = storiesSet.toList();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => StoryScreen(storiesList)),
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
