import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

uploadImagetFirebase(String imagePath) async {
  await FirebaseStorage.instance
      .ref(imagePath)
      .putFile(File(imagePath))
      .then((taskSnapshot) {
    print("task done");

// download url when it is uploaded
    if (taskSnapshot.state == TaskState.success) {
      FirebaseStorage.instance
          .ref(imagePath)
          .getDownloadURL()
          .then((url) {
        print("Here is the URL of Image $url");
        return url;
      }).catchError((onError) {
        print("Got Error $onError");
      });
    } else {
      print('feck');
    }
  });
  print('bugga');
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> firebasePlaylist =
    FirebaseFirestore.instance.collection('playlist').snapshots();

    uploadImagetFirebase('/Users/colinrafter/StudioProjects/barbs_bedtime_stories/assets/music/pray.mp3');

    return Scaffold(
      backgroundColor: Colors.deepPurple.shade600,
      //appBar: const CustomAppBar(),
      body: SafeArea(
        child: Padding(
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
      ),
    );
  }
}