import 'dart:io';

import 'package:favorite_button/favorite_button.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart' as rxdart;

import '../models/story_model.dart';
import '../widgets/widgets.dart';

class StoryScreen extends StatefulWidget {
  const StoryScreen(this.story, {Key? key}) :
        super(key: key);
  final Story story;

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  AudioPlayer audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();

    final items = [
      AudioSource.uri(Uri.parse('https://example.com/track1.mp3')),
      AudioSource.uri(Uri.parse('https://example.com/track2.mp3')),
      AudioSource.uri(Uri.parse('https://example.com/track3.mp3')),
    ];

    //https://stackoverflow.com/questions/73339177/flutter-with-just-audio-is-it-possible-to-create-a-playlist-that-doesnt-aut/73342727#73342727

    audioPlayer.setAudioSource(items[0]);

    audioPlayer.setAudioSource(
      ConcatenatingAudioSource(
        children: [
          AudioSource.uri(
            Uri.parse('asset:///${widget.story.url}'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  Stream<SeekBarData> get _seekBarDataStream =>
      rxdart.Rx.combineLatest2<Duration, Duration?, SeekBarData>(
          audioPlayer.positionStream, audioPlayer.durationStream, (
        Duration position,
        Duration? duration,
      ) {
        return SeekBarData(
          position,
          duration ?? Duration.zero,
        );
      });

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
            widget.story.coverUrl,
            fit: BoxFit.cover,
          ),
          const _BackgroundFilter(),
          _MusicPlayer(
            story: widget.story,
            seekBarDataStream: _seekBarDataStream,
            audioPlayer: audioPlayer,
          ),
        ],
      ),
    );
  }
}

class _MusicPlayer extends StatefulWidget{

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

  _MusicPlayerState createState()=> _MusicPlayerState();
}

class _MusicPlayerState extends State<_MusicPlayer>{
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

                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: widget.favorite ? Text('Added to favourites') : Text('Removed from favourites') ,
                  ),);
                },
              ),
              IconButton(
                  onPressed: () async {
                    final dir = await getApplicationDocumentsDirectory();
                    final file = File('${dir.path}/raf.file');

                    print(dir.path);
                    print(file);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Downloaded'),)
                    );
                  },
                  icon:  const Icon(
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