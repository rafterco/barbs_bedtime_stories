import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../global/globals.dart';
import '../models/playlist_model.dart';
import '../models/story_model.dart';
import '../widgets/widgets.dart';
import 'package:flutter_svg/svg.dart';

// playlist -> stories?


class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Playlist> playlists = [];

    return Scaffold(
      backgroundColor: Colors.deepPurple.shade600,
      //appBar: const CustomAppBar(),
      body: SafeArea(
        child: Stack(
          children: [
            SvgPicture.asset(
              'assets/images/bg_home_border.svg',
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              alignment: AlignmentDirectional.topStart,
            ),
            SvgPicture.asset(
              'assets/images/bg_moon_home.svg',
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              alignment: AlignmentDirectional.topStart,
            ),
            Column(children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const _DiscoverStories(),
                      _TrendingStories(),
                      SizedBox(
                        height: 700,
                        child: _PlaylistStories(playlists: playlists),
                      ),
                    ],
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _PlaylistStories extends StatelessWidget {
  const _PlaylistStories({
    Key? key,
    required this.playlists,
  }) : super(key: key);

  final List<Playlist> playlists;

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> firebasePlaylist =
        FirebaseFirestore.instance.collection('playlist').snapshots();

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const SectionHeader(title: 'Recommended Playlists'),
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
                      stories: data.docs[index]['stories'].cast<String>(),
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
    );
  }
}

Future getStories() async {
  await FirebaseFirestore.instance
      .collection("playlist")
      .get()
      .then((snapshot) => snapshot.docs.forEach((playlist) {
          Global.playLists.add(Playlist(
                title: playlist['title'],
                stories: playlist['stories'].cast<String>(),
                imageUrl: playlist['imageUrl']));
          }));

  await FirebaseFirestore.instance
      .collection("stories")
      .get()
      .then((storySnapshot) => storySnapshot.docs.forEach((story) {
            Global.stories.add(Story(
                title: story['title'],
                description: story['description'],
                url: story['url'],
                coverUrl: story['coverUrl']));
          }));

  for (Playlist p in Global.playLists) {
    for (Story s in Global.stories) {
      if (Global.playListStoriesToStory.containsKey(p.title)) {
        Set<Story>? storyList = Global.playListStoriesToStory[p.title];
        if (p.stories.contains(s.title) && storyList != null && !storyList.contains(s)) {
          storyList.add(s);
        }
      } else {
        Global.playListStoriesToStory.putIfAbsent(p.title, () => {s});
      }
    }
  }

  print(Global.playListStoriesToStory);
}

class _TrendingStories extends StatelessWidget {
  _TrendingStories({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //Future<List<Story>> _stories = _getEventsFromFirestore();
    getStories();

    final Stream<QuerySnapshot> stories =
        FirebaseFirestore.instance.collection('stories').snapshots();

    return Padding(
      padding: const EdgeInsets.only(
        left: 20.0,
        top: 20.0,
        bottom: 20.0,
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 20.0),
            child: SectionHeader(title: 'Trending Stories'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.20,
            child: StreamBuilder<QuerySnapshot>(
              stream: stories,
              builder: (
                BuildContext context,
                AsyncSnapshot<QuerySnapshot> snapshot,
              ) {
                if (snapshot.hasError) {
                  return const Text('error downloading stories');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.requireData;
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: data.size,
                  itemBuilder: (context, index) {
                    Story story = Story(
                        title: data.docs[index]['title'],
                        description: data.docs[index]['description'],
                        url: data.docs[index]['url'],
                        coverUrl: data.docs[index]['coverUrl']);
                    List<Story> stories = [];
                    stories.add(story);

                    return Row(children: [StoryCard(stories: stories)]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverStories extends StatelessWidget {
  const _DiscoverStories({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 80),
          Text(
            'Welcome',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 3),
          Text(
            'Enjoy your favorite bedtime stories',
            style: Theme.of(context)
                .textTheme
                .headline6!
                .copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
