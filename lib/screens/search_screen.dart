import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/playlist_model.dart';
import '../models/story_model.dart';
import '../widgets/widgets.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Playlist> playlists = [];


  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();

    final Stream<QuerySnapshot> firebasePlaylist =
        FirebaseFirestore.instance.collection('playlist').snapshots();


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
                        prefixIcon: const Icon(Icons.search, color: Colors.white,),
                        hintText: 'title',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: Colors.black)),
                      ),
                      onChanged: searchPlaylists,
                    )),
                FutureBuilder(
                    future: getData(),
                    builder: (context, AsyncSnapshot snapshot) {
                      if (!snapshot.hasData) {
                        return CircularProgressIndicator();
                      } else {
                        return Expanded(
                          child: ListView.builder(
                            itemCount: snapshot.data.length,
                            itemBuilder: (BuildContext context, int index) {
                              var title = snapshot.data[index]['title'];
                              var stories = List<String>.from(snapshot.data[index]['stories']);
                              var imageUrl = snapshot.data[index]['imageUrl'];
                              Playlist playlist = Playlist(
                                  title: title,
                                  stories: stories,
                                  imageUrl: imageUrl);

                              //final playlist = playlists[index];
                              return PlaylistCard(playlist: playlist);
                            },
                          ),
                        );
                      }
                    }),
                /*Expanded(
                  child: ListView.builder(
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = playlists[index];
                      return PlaylistCard(playlist: playlist);
                    },
                  ),
                ),*/

                /* StreamBuilder<QuerySnapshot>(
                  stream: firebasePlaylist,
                  builder: (
                      BuildContext context,
                      AsyncSnapshot<QuerySnapshot> snapshot,
                      ) {
                    if (snapshot.hasError) {
                      return const Text('error downloading Stories');
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text('downloading data');
                    }

                    final data = snapshot.requireData;
                    return Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: data.size,
                        itemBuilder: (context, index) {
                          Playlist pl = Playlist(
                            title: data.docs[index]['title'],
                            stories: data.docs[index]['stories'].cast<String>(),
                            imageUrl: data.docs[index]['imageUrl'],
                          );
                          return PlaylistCard(playlist: pl);
                        },
                      ),
                    );
                  },
                ),*/
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
        playlists.add(playlist);
      }
    });

    return playlists;
  }

  void searchPlaylists(String query) {
    final suggestions = playlists.where((story) {
      final playlistTitle = story.title.toLowerCase();
      final input = query.toLowerCase();

      return playlistTitle.contains(input);
    }).toList();

    setState(() => playlists = suggestions);
  }
}
