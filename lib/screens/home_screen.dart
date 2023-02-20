import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/playlist_model.dart';
import '../models/song_model.dart';
import '../widgets/widgets.dart';
import 'package:flutter_svg/svg.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Song> songs = Song.songs;
    List<Playlist> playlists = [];//Playlist.playlists; //rafraf

      return Scaffold(
        backgroundColor: Colors.deepPurple.shade600,
        appBar: const _CustomAppBar(),

        body: Stack(children: [
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
                    const _DiscoverMusic(),
                    _TrendingStories(songs: songs),
                    SizedBox(
                      height: 700,
                      child: _PlaylistMusic(playlists: playlists),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ],),);
  }
}

class _PlaylistMusic extends StatelessWidget {
  _PlaylistMusic({
    Key? key,
    required this.playlists,
  }) : super(key: key);

  List<Playlist> playlists;

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> users =
    FirebaseFirestore.instance.collection('users').snapshots();

    final Stream<QuerySnapshot> firebasePlaylist =
    FirebaseFirestore.instance.collection('playlist').snapshots();

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(

        /*
        children: [
          const SectionHeader(title: 'Recommended Playlists'),
          ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.only(top: 20),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: playlists.length,
            itemBuilder: ((context, index) {
              return PlaylistCard(playlist: playlists[index]);
            }),
          ),
        ],
         */

          // firebasePlaylist.forEach((element) {
          //   List<Song> songs = element.docs[0]['stories'].cast<Song>();
          //   Playlist playList = Playlist(
          //       title: element.docs[0]['title'],
          //       songs: songs,
          //       imageUrl: element.docs[0]['imageUrl']
          //   );
          //   playlists.add(playList);
          // });

          children: [
            SectionHeader(title: 'Recommended Playlists'),
            StreamBuilder<QuerySnapshot>(
              stream: firebasePlaylist,
              builder: (
                  BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot,) {
                if (snapshot.hasError) {
                  return Text('error downloading storeis');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text('downloading data');
                }

                final data = snapshot.requireData;
                return Container(
                  child: Expanded(
                    child: ListView.builder(
                      itemCount: data.size,
                      itemBuilder: (context, index) {
                        Playlist pl = Playlist(
                          title: data.docs[index]['title'],
                          songs: data.docs[index]['stories'].cast<Song>(),
                          imageUrl: data.docs[index]['imageUrl'],
                        );
                        return PlaylistCard(playlist: pl);
                        },
                    ),
                  ),
                );},
            ),
          ],
        // children: [
        //   SectionHeader(title: 'Recommended Playlists'),
        //   StreamBuilder<QuerySnapshot>(
        //     stream: users,
        //     builder: (
        //         BuildContext context,
        //         AsyncSnapshot<QuerySnapshot> snapshot,
        //     )
        //     {
        //
        //       if (snapshot.hasError) {
        //         return Text('error downloading storeis');
        //       }
        //       if (snapshot.connectionState == ConnectionState.waiting) {
        //         return Text('downloading data');
        //       }
        //
        //       final data = snapshot.requireData;
        //       print ('size: ${data.size}');
        //       //return Text('Raf ${data.docs[1]['firstname']} a raf ${data.docs[1]['surname']}');
        //
        //       return Container(
        //
        //         child: Expanded(
        //
        //           child: ListView.builder(
        //             itemCount: data.size,
        //             itemBuilder: (context, index) {
        //               return Text('Raf ${data.docs[index]['firstname']} a raf ${data.docs[index]['surname']}');
        //             },
        //           ),
        //         ),
        //       );
        //     },
        //   ),
        // ],
      ),
    );
  }
}

class _TrendingStories extends StatelessWidget {
  const _TrendingStories({
    Key? key,
    required this.songs,
  }) : super(key: key);

  final List<Song> songs;

  @override
  Widget build(BuildContext context) {
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
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: songs.length,
              itemBuilder: (context, index) {
                return SongCard(song: songs[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverMusic extends StatelessWidget {
  const _DiscoverMusic({
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
            'Welcome Kyla',
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

class _CustomNavBar extends StatelessWidget {
  const _CustomNavBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.deepPurple.shade800,
      unselectedItemColor: Colors.white,
      selectedItemColor: Colors.white,
      showUnselectedLabels: false,
      showSelectedLabels: false,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite_outline),
          label: 'Favorites',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.play_circle_outline),
          label: 'Play',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          label: 'Profile',
        ),
      ],
    );
  }
}

class _CustomAppBar extends StatelessWidget with PreferredSizeWidget {
  const _CustomAppBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      leading: const Icon(Icons.grid_view_rounded),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 20),
          child: const CircleAvatar(
            backgroundImage: NetworkImage(
              'https://images.unsplash.com/photo-1659025435463-a039676b45a0?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1287&q=80',
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56.0);
}
