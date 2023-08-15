import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

import '../models/playlist_model.dart';
import '../models/story_model.dart';


class Global {
  static Set<Story> stories = {};
  static Set<Playlist> playLists = {};
  static Map<String, Set<Story>> playListTitleToStories = HashMap<String, Set<Story>>();

  static Future<void>  getStories() async {
    await FirebaseFirestore.instance
        .collection("playlist")
        .get()
        .then((snapshot) => snapshot.docs.forEach((playlist) async {
      final ref = firebase_storage.FirebaseStorage.instance.refFromURL(playlist['imageUrl']);
      final imageUrl = await ref.getDownloadURL();

      Global.playLists.add(Playlist(
          title: playlist['title'],
          stories: playlist['stories'].cast<String>(),
          imageUrl: imageUrl));
    }));

    await FirebaseFirestore.instance
        .collection("stories")
        .get()
        .then((storySnapshot) => storySnapshot.docs.forEach((story) {
      Global.stories.add(Story(
          title: story['title'],
          description: story['description'],
          url: story['url'],
          cloudUrl: story['cloudUrl'],
          coverUrl: story['coverUrl']));
    }));

    await organise();
  }

  static Future<void> organise() async {
    for (Playlist p in Global.playLists) {
      for (Story s in Global.stories) {
        if (Global.playListTitleToStories.containsKey(p.title)) {
          Set<Story>? storyList = Global.playListTitleToStories[p.title];
          if (p.stories.contains(s.title) && storyList != null && !storyList.contains(s)) {
            storyList.add(s);
          }
        } else {
          Global.playListTitleToStories.putIfAbsent(p.title, () => {s});
        }
      }
    }
  }
}

