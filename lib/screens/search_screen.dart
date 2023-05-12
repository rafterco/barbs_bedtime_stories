import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/playlist_model.dart';
import '../widgets/widgets.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Playlist> allPlaylists = [];
  List<Playlist> displayPlaylists = [];

  late Future<List<Playlist>> _future;

  @override
  void initState() {
    super.initState();
    _future = populatePlaylistFromFirebase();
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
                const SectionHeader(title: 'Search online library'),
                const SizedBox(height: 18),
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
                      onChanged: searchPlaylists,
                    )),
                Expanded(
                  child: FutureBuilder(
                      future: _future,
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
                ),
              ],
            ),
          ),
        ),
      ),
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

  void searchPlaylists(String query) {
    final suggestions = allPlaylists.where((story) {
      final playlistTitle = story.title.toLowerCase();
      final input = query.toLowerCase();

      return playlistTitle.contains(input);
    }).toList();

    setState(() => displayPlaylists  = suggestions);
  }
}
