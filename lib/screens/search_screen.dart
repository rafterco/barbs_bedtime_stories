import 'package:barbs_bedtime_stories/models/story_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/playlist_model.dart';
import '../widgets/story_search_card.dart';
import '../widgets/widgets.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Playlist> allPlaylists = [];
  List<Playlist> displayPlaylists = [];

  List<Story> allStories = [];
  List<Story> displayStories = [];

  late Future<List<Playlist>> _playlistFuture;
  late Future<List<Story>> _storiesFuture;

  List<Widget> fruits = <Widget>[
    const Text('Stories'),
    const Text('Playlists')
  ];

  final List<bool> _selected = <bool>[true, false];

  bool isPlaylist = true;

  @override
  void initState() {
    super.initState();
    _playlistFuture = populatePlaylistFromFirebase();
    _storiesFuture = populateStoriesFromFirebase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Colors.blue,
          Colors.red,
        ],
      )),
      child: Scaffold(
        backgroundColor: Colors.deepPurple.shade600,
        //appBar: const CustomAppBar(),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(height: 20,),
                const SectionHeader(title: 'Search library'),
                const SizedBox(
                  height: 20,
                ),
                ToggleButtons(
                  direction: Axis.horizontal,
                  onPressed: (int index) {
                    setState(() {
                      // The button that is tapped is set to true, and the others to false.
                      for (int i = 0; i < _selected.length; i++) {
                        _selected[i] = i == index;
                        isPlaylist = _selected[0] == true;
                      }
                    });
                  },
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  //Colors.deepPurple.shade600,
                  selectedBorderColor: Colors.black,
                  selectedColor: Colors.white,
                  fillColor: Colors.deepPurple.shade800,
                  color: Colors.white38,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  constraints: const BoxConstraints(
                    minHeight: 40.0,
                    minWidth: 80.0,
                  ),
                  isSelected: _selected,
                  children: fruits,
                ),
                const SizedBox(height: 0),
                Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: TextField(
                      //controller: controller,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.white,
                        ),
                        hintText: 'title',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: Colors.black)),
                      ),
                      onChanged: isPlaylist ? searchStories : searchPlaylists,
                    )),
                isPlaylist ?  buildStories() : buildPlaylist(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Expanded buildPlaylist() {
    return Expanded(
      child: FutureBuilder(
          future: _playlistFuture,
          builder: (context, AsyncSnapshot snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                  child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.amber),
              ));
            } else {
              return ListView.builder(
                itemCount: displayPlaylists.length,
                itemBuilder: (BuildContext context, int index) {
                  final playlist = displayPlaylists[index];
                  return PlaylistCard(playlist: playlist);
                },
              );
            }
          }),
    );
  }

  Expanded buildStories() {
    return Expanded(
      child: FutureBuilder(
          future: _storiesFuture,
          builder: (context, AsyncSnapshot snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                  child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.amber),
              ));
            } else {
              return ListView.builder(
                itemCount: displayStories.length,
                itemBuilder: (BuildContext context, int index) {
                  final story = displayStories[index];
                  return StorySearchCard(story: story);
                },
              );
            }
          }),
    );
  }

  Future<List<DocumentSnapshot>> getData() async {
    QuerySnapshot qn =
        await FirebaseFirestore.instance.collection('playlist').get();

    return qn.docs;
  }

  Future<List<Playlist>> populatePlaylistFromFirebase() async {
    await FirebaseFirestore.instance
        .collection('playlist')
        .get()
        .then((querySnapshot) {
      for (var doc in querySnapshot.docs) {
        var imageUrl = doc.get('imageUrl');
        var title = doc.get('title');
        var storiesList = doc.get('stories');
        List<String> stories = List.of(storiesList).cast<String>();

        Playlist playlist =
            Playlist(title: title, stories: stories, imageUrl: imageUrl);
        allPlaylists.add(playlist);
      }
    });
    displayPlaylists = allPlaylists;

    return allPlaylists;
  }

  Future<List<Story>> populateStoriesFromFirebase() async {
    await FirebaseFirestore.instance
        .collection('stories')
        .get()
        .then((querySnapshot) {
      for (var doc in querySnapshot.docs) {
        var coverUrl = doc.get('coverUrl');
        var description = doc.get('description');
        var title = doc.get('title');
        var url = doc.get('url');
        var cloudUrl = doc.get('cloudUrl');

        Story story = Story(
            title: title,
            description: description,
            url: url,
            cloudUrl: cloudUrl,
            coverUrl: coverUrl);
        allStories.add(story);
      }
    });
    displayStories = allStories;

    return allStories;
  }

  void searchPlaylists(String query) {
    final suggestions = allPlaylists.where((story) {
      final playlistTitle = story.title.toLowerCase();
      final input = query.toLowerCase();

      return playlistTitle.contains(input);
    }).toList();

    setState(() => displayPlaylists = suggestions);
  }

  void searchStories(String query) {
    final suggestions = allStories.where((story) {
      final storyTitle = story.title.toLowerCase();
      final input = query.toLowerCase();

      return storyTitle.contains(input);
    }).toList();

    setState(() => displayStories = suggestions);
  }
}
