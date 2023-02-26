import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/playlist_model.dart';
import '../models/story_model.dart';
import '../widgets/playlist_card.dart';
import '../widgets/section_header.dart';
import '../widgets/widgets.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({Key? key}) :
        super(key: key);
  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> firebasePlaylist =
    FirebaseFirestore.instance.collection('playlist').snapshots();

    return Scaffold(
      backgroundColor: Colors.deepPurple.shade600,
      appBar: const CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SectionHeader(title: 'Favourites'),
            SizedBox(height: 18,),
            StreamBuilder<QuerySnapshot>(
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
                        songs: data.docs[index]['stories'].cast<Story>(),
                        imageUrl: data.docs[index]['imageUrl'],
                      );
                      return PlaylistCard(playlist: pl);
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}