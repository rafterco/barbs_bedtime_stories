import 'dart:collection';

import 'package:barbs_bedtime_stories/screens/navigation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'models/story_model.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

void init() {

  getStories();

  // Create a new user document
  DocumentReference userRef =
  FirebaseFirestore.instance.collection("users").doc("user1");
  Map<String, Object> user = {
    "name": "John Doe",
  };
  userRef.set(user);

  DocumentReference postRef =
  FirebaseFirestore.instance.collection("posts").doc("post1");
  Map<String, Object> post = {
    "title": "My Post",
    "userId": userRef,
  };
  postRef.set(post);
}

List<dynamic> _stories = [];
Map<String, Map<String, String>> _playListStoriesToStory = HashMap<String, Map<String, String>>();

Future getStories() async {
  await FirebaseFirestore.instance
      .collection("playlist")
      .get()
      .then((snapshot) => snapshot.docs.forEach((playlist) {
    List<dynamic> playlistStories = playlist.get("stories");

    for (String playlist in playlistStories) {
      print(playlist);
    }

    //_stories.add(Story(title: document.reference.id, description: '', url: '', coverUrl: ''));
  }));

  FirebaseFirestore.instance
      .collection("stories")
      .get()
      .then((storySnapshot) => storySnapshot.docs.forEach((story) {
    print(story);
    _stories.add(
        Story(
            title: story['title'],
            description: story['description'],
            url: story['url'],
            cloudUrl: story['cloudUrl'],
            coverUrl: story['coverUrl']));
  }));

  for (Story s in _stories) {
    print(s);
  }
}



class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
      ),
      home: Navigation(),
    );
  }
}
