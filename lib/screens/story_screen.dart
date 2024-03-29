import 'dart:io';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:favorite_button/favorite_button.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../models/notifier/play_button_notifier.dart';
import '../models/notifier/progress_notifier.dart';
import '../models/notifier/repeat_button_notifier.dart';
import '../models/page_manager.dart';
import '../models/story_model.dart';
import '../widgets/widgets.dart';

class StoryScreen extends StatefulWidget {
  const StoryScreen(this.stories, {Key? key}) : super(key: key);
  final List<Story> stories;

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

late PageManager _pageManager;

class _StoryScreenState extends State<StoryScreen> {
  AudioPlayer audioPlayer = AudioPlayer();


  @override
  void initState() {
    super.initState();

    _pageManager = PageManager(widget.stories); //.setInitialPlaylist(items);

    // this is the shit
    //https://suragch.medium.com/managing-playlists-in-flutter-with-just-audio-c4b8f2af12eb
    //https://github.com/suragch/audio_playlist_flutter_demo/blob/master/final/lib/main.dart#L16

  }

  @override
  void dispose() {
    _pageManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            widget.stories[0].coverUrl,
            fit: BoxFit.cover,
          ),
          //const _BackgroundFilter(),
          const Padding(
            padding: EdgeInsets.fromLTRB(40, 100, 40, 100),
            child: Column(
              children: [
                CurrentSongTitle(),
                PlaylistWidget(),
                //AddRemoveSongButtons(),
                AudioProgressBar(),
                AudioControlButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MusicPlayer extends StatefulWidget {
  _MusicPlayer({
    Key? key,
    required this.story,
    required Stream<SeekBarData> seekBarDataStream,
    required this.audioPlayer,
  })  : _seekBarDataStream = seekBarDataStream,
        super(key: key);

  final Story story;
  final Stream<SeekBarData> _seekBarDataStream;
  final AudioPlayer audioPlayer;
  bool favorite = false;
  bool downloaded = false;

  @override
  _MusicPlayerState createState() => _MusicPlayerState();
}

class _MusicPlayerState extends State<_MusicPlayer> {
  @override
  // TODO: implement widget
  _MusicPlayer get widget => super.widget;

  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 50.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.story.title,
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.story.description,
            maxLines: 2,
            style: Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(color: Colors.white),
          ),
          const SizedBox(height: 30),
          StreamBuilder<SeekBarData>(
            stream: widget._seekBarDataStream,
            builder: (context, snapshot) {
              final positionData = snapshot.data;
              return SeekBar(
                position: positionData?.position ?? Duration.zero,
                duration: positionData?.duration ?? Duration.zero,
                onChangeEnd: widget.audioPlayer.seek,
              );
            },
          ),
          PlayerButtons(audioPlayer: widget.audioPlayer),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FavoriteButton(
                isFavorite: widget.favorite,
                valueChanged: (isFavorite) {
                  setState(() {
                    widget.favorite = isFavorite;
                  });
                  //todo save to firebase
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: widget.favorite
                          ? const Text('Added to favourites')
                          : const Text('Removed from favourites'),
                    ),
                  );
                },
              ),
              IconButton(
                onPressed: () async {
                  final dir = await getApplicationDocumentsDirectory();
                  final file = File('${dir.path}/raf.file');

                  print(dir.path);
                  print(file);

                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Downloaded'),
                  ));
                },
                icon: const Icon(
                  Icons.cloud_download,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BackgroundFilter extends StatelessWidget {
  const _BackgroundFilter({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) {
        return LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.white.withOpacity(0.5),
              Colors.white.withOpacity(0.0),
            ],
            stops: const [
              0.0,
              0.4,
              0.6
            ]).createShader(rect);
      },
      blendMode: BlendMode.dstOut,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade200,
              Colors.deepPurple.shade800,
            ],
          ),
        ),
      ),
    );
  }
}

class CurrentSongTitle extends StatelessWidget {
  const CurrentSongTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: _pageManager.currentSongTitleNotifier,
      builder: (_, title, __) {
        return Padding(
          padding: const EdgeInsets.only(top: 25.0),
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .headlineSmall!
                .copyWith(fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}

class PlaylistWidget extends StatelessWidget {
  const PlaylistWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ValueListenableBuilder<List<String>>(
        valueListenable: _pageManager.playlistNotifier,
        builder: (context, playlistTitles, _) {
          return ListView.builder(
            itemCount: playlistTitles.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(
                  playlistTitles[index],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        offset: Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AddRemoveSongButtons extends StatelessWidget {
  const AddRemoveSongButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      ),
    );
  }
}

class AudioProgressBar extends StatelessWidget {
  const AudioProgressBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ProgressBarState>(
      valueListenable: _pageManager.progressNotifier,
      builder: (_, value, __) {
        return ProgressBar(
          progress: value.current,
          buffered: value.buffered,
          total: value.total,
          onSeek: _pageManager.seek,
        );
      },
    );
  }
}


class AudioControlButtons extends StatelessWidget {
  const AudioControlButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          RepeatButton(),
          PreviousSongButton(),
          PlayButton(),
          NextSongButton(),
          ShuffleButton(),
        ],
      ),
    );
  }
}

class RepeatButton extends StatelessWidget {
  const RepeatButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RepeatState>(
      valueListenable: _pageManager.repeatButtonNotifier,
      builder: (context, value, child) {
        Icon icon;
        switch (value) {
          case RepeatState.off:
            icon = Icon(Icons.repeat, color: Colors.grey);
            break;
          case RepeatState.repeatSong:
            icon = Icon(Icons.repeat_one);
            break;
          case RepeatState.repeatPlaylist:
            icon = Icon(Icons.repeat);
            break;
        }
        return IconButton(
          icon: icon,
          onPressed: _pageManager.onRepeatButtonPressed,
        );
      },
    );
  }
}

class PreviousSongButton extends StatelessWidget {
  const PreviousSongButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _pageManager.isFirstSongNotifier,
      builder: (_, isFirst, __) {
        return IconButton(
          icon: const Icon(Icons.skip_previous, color: Colors.blueGrey),
          onPressed:
              (isFirst) ? null : _pageManager.onPreviousSongButtonPressed,
        );
      },
    );
  }
}

class PlayButton extends StatelessWidget {
  const PlayButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ButtonState>(
      valueListenable: _pageManager.playButtonNotifier,
      builder: (_, value, __) {
        switch (value) {
          case ButtonState.loading:
            return Container(
              margin: const EdgeInsets.all(8.0),
              width: 32.0,
              height: 32.0,
              child: const CircularProgressIndicator(),
            );
          case ButtonState.paused:
            return IconButton(
              //icon: const Icon(Icons.play_arrow),
              icon: const Icon(Icons.play_arrow, color: Colors.blueGrey),
              iconSize: 32.0,
              onPressed: _pageManager.play,
            );
          case ButtonState.playing:
            return IconButton(
              icon: const Icon(Icons.pause, color: Colors.blueGrey),
              iconSize: 32.0,
              onPressed: _pageManager.pause,
            );
        }
      },
    );
  }
}

class NextSongButton extends StatelessWidget {
  const NextSongButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _pageManager.isLastSongNotifier,
      builder: (_, isLast, __) {
        return IconButton(
          icon: const Icon(Icons.skip_next, color: Colors.blueGrey),
          onPressed: (isLast) ? null : _pageManager.onNextSongButtonPressed,
        );
      },
    );
  }
}

class ShuffleButton extends StatelessWidget {
  const ShuffleButton({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _pageManager.isShuffleModeEnabledNotifier,
      builder: (context, isEnabled, child) {
        return IconButton(
          icon: (isEnabled)
              ? const Icon(Icons.shuffle)
              : const Icon(Icons.shuffle, color: Colors.grey),
          onPressed: _pageManager.onShuffleButtonPressed,
        );
      },
    );
  }
}
