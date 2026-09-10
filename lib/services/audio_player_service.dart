import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:rxdart/rxdart.dart';

import 'package:audio_session/audio_session.dart';
import 'package:barbs_bedtime_stories/data/models/playlist.dart';
import 'package:barbs_bedtime_stories/data/models/story.dart';
import 'package:barbs_bedtime_stories/services/ambient_sound_service.dart';
import 'package:barbs_bedtime_stories/services/download_service.dart';
import 'package:video_player/video_player.dart';

enum BedtimeRepeatMode {
  off,
  all,
  one,
}

/// Aggregated position data for the progress bar.
class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}

/// Global audio player service that manages playback, background audio,
/// sleep timer, and recently played tracking.
///
/// This is a singleton — use [AudioPlayerService.instance] to access it.
class AudioPlayerService {
  AudioPlayerService._();
  static final AudioPlayerService instance = AudioPlayerService._();

  late final BaseAudioHandler _audioHandler;
  final AudioPlayer _player = AudioPlayer();

  // ── State ──
  final ValueNotifier<Story?> currentStory = ValueNotifier(null);
  final ValueNotifier<Playlist?> currentPlaylist = ValueNotifier(null);
  final ValueNotifier<List<Story>> playlistQueueNotifier = ValueNotifier([]);
  final ValueNotifier<int> currentQueueIndexNotifier = ValueNotifier(-1);
  final ValueNotifier<BedtimeRepeatMode> repeatMode =
      ValueNotifier(BedtimeRepeatMode.off);
  final ValueNotifier<bool> isPlaying = ValueNotifier(false);
  final ValueNotifier<String?> playbackError = ValueNotifier(null);
  final ValueNotifier<int?> sleepTimerMinutes = ValueNotifier(null);
  final ValueNotifier<Duration?> sleepTimerRemaining = ValueNotifier(null);
  final ValueNotifier<bool> isVideoPlayerFullScreen = ValueNotifier(false);

  final BehaviorSubject<PositionData> _positionDataSubject =
      BehaviorSubject<PositionData>.seeded(
    PositionData(Duration.zero, Duration.zero, Duration.zero),
  );

  Timer? _sleepTimer;
  Timer? _sleepCountdownTimer;
  StreamSubscription<PlayerState>? _endOfStorySubscription;
  bool _initialized = false;
  int _audioTimeoutSeconds = 45;
  int _playRequestId = 0;

  AudioPlayer get player => _player;
  int get audioTimeoutSeconds => _audioTimeoutSeconds;

  void updateAudioTimeout(int seconds) {
    if (seconds >= 5 && seconds <= 180) {
      _audioTimeoutSeconds = seconds;
    }
  }

  /// Initialize audio_service and audio_session for background/lock-screen playback.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Configure system audio session with mixWithOthers for seamless story + ambient sound mixing
    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.mixWithOthers,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ),
    );

    // Initialize background audio handler to publish metadata to iOS MPNowPlayingInfoCenter & Control Center
    _audioHandler = await AudioService.init(
      builder: () => _BedtimeAudioHandler(_player),
      config: const AudioServiceConfig(
        androidNotificationChannelId:
            'com.rafterco.barbs_bedtime_stories.audio',
        androidNotificationChannelName: "Barbara's Bedtime Stories",
        androidNotificationOngoing: false,
        androidStopForegroundOnPause: false,
        androidNotificationIcon: 'mipmap/barbs_sleep_stories',
        preloadArtwork: false,
      ),
    );

    // Sync playing state and handle story completion
    _player.playerStateStream.listen(
      (state) {
        if (_activeVideoController == null) {
          isPlaying.value = state.playing;
        }
        if (state.playing) {
          AmbientSoundService.instance.resumeActiveSounds();
        } else {
          AmbientSoundService.instance.pauseActiveSounds();
        }
        if (state.processingState == ProcessingState.completed) {
          _onStoryPlaybackCompleted();
        }
      },
      onError: (e, st) {
        debugPrint('playerStateStream error: $e');
      },
    );

    Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
      _player.positionStream,
      _player.bufferedPositionStream,
      _player.durationStream,
      (position, bufferedPosition, duration) => PositionData(
        position,
        bufferedPosition,
        duration ?? Duration.zero,
      ),
    ).listen(
      (data) {
        if (_activeVideoController == null) {
          _positionDataSubject.add(data);
        }
      },
      onError: (e, st) {
        debugPrint('positionDataStream error: $e');
      },
    );

    // Handle audio interruptions (phone calls, Siri, alarms)
    bool playInterrupted = false;
    double preDuckVolume = 1.0;

    session.interruptionEventStream.listen(
      (event) {
        if (event.begin) {
          switch (event.type) {
            case AudioInterruptionType.duck:
              preDuckVolume = _player.volume;
              _player.setVolume(_player.volume * 0.5);
              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              playInterrupted = _player.playing;
              _player.pause();
              break;
          }
        } else {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _player.setVolume(preDuckVolume);
              break;
            case AudioInterruptionType.pause:
              if (playInterrupted) {
                _player.play();
                playInterrupted = false;
              }
              break;
            case AudioInterruptionType.unknown:
              break;
          }
        }
      },
      onError: (e, st) {
        debugPrint('interruptionEventStream error: $e');
      },
    );

    // Pause when headphones are unplugged
    session.becomingNoisyEventStream.listen(
      (_) {
        _player.pause();
      },
      onError: (e, st) {
        debugPrint('becomingNoisyEventStream error: $e');
      },
    );
  }

  void _onStoryPlaybackCompleted() {
    if (repeatMode.value == BedtimeRepeatMode.one) {
      _player.seek(Duration.zero);
      _player.play();
      return;
    }
    if (_playlistQueue.isNotEmpty && autoPlayEnabled.value) {
      if (_currentQueueIndex + 1 < _playlistQueue.length) {
        _startAutoPlayCountdown();
      } else if (repeatMode.value == BedtimeRepeatMode.all) {
        _currentQueueIndex = -1;
        _startAutoPlayCountdown();
      }
    }
  }

  /// Combined stream of position, buffer, and duration.
  Stream<PositionData> get positionDataStream => _positionDataSubject.stream;

  /// Load and play a story.
  Future<void> playStory(
    Story story, {
    Playlist? playlist,
    bool keepPlaylistContext = false,
    Duration initialPosition = Duration.zero,
  }) async {
    final requestId = ++_playRequestId;
    isVideoPlayerFullScreen.value = false;

    // Disconnect and stop any active video playback immediately so audio never collides
    if (_activeVideoController != null) {
      final ctrl = _activeVideoController!;
      _activeVideoController = null;
      ctrl.removeListener(_onVideoControllerUpdate);
      try {
        await ctrl.pause();
        await ctrl.dispose();
      } catch (_) {}
    }

    currentStory.value = story;
    playbackError.value = null;

    if (playlist != null) {
      currentPlaylist.value = playlist;
    } else if (!keepPlaylistContext) {
      currentPlaylist.value = null;
      _playlistQueue = [story];
      playlistQueueNotifier.value = [story];
      _currentQueueIndex = 0;
      currentQueueIndexNotifier.value = 0;
    }

    // 1. Immediately publish metadata to iOS MPNowPlayingInfoCenter & Android MediaStyle notification
    // On iOS, pass artUri for lock screen Control Center. On Android, omit remote Uri to prevent 10MB TransactionTooLargeException
    final resolvedCover = resolveStorageUrl(story.coverImageUrl);
    final artUri = (Platform.isIOS &&
            (resolvedCover.startsWith('http://') ||
                resolvedCover.startsWith('https://') ||
                resolvedCover.startsWith('file://')))
        ? Uri.tryParse(resolvedCover)
        : null;

    try {
      _audioHandler.mediaItem.add(
        MediaItem(
          id: story.id,
          title: story.title,
          artist: story.narrator,
          album: currentPlaylist.value?.title ?? (story.isVideo ? 'Storytime with Barbara' : "Barbara's Bedtime Stories"),
          artUri: artUri,
          duration: Duration(seconds: story.duration),
        ),
      );
    } catch (e) {
      debugPrint('Error publishing mediaItem metadata: $e');
    }

    var targetUrl = story.audioUrl.trim();
    if (targetUrl.isEmpty && story.effectiveVideoUrl.isNotEmpty) {
      targetUrl = story.effectiveVideoUrl;
    }
    if (!targetUrl.startsWith('http://') &&
        !targetUrl.startsWith('https://') &&
        !targetUrl.startsWith('file://')) {
      targetUrl = resolveStorageUrl(targetUrl);
    }

    if (targetUrl.isEmpty) {
      playbackError.value = 'Story audio not available yet.';
      return;
    }

    try {
      await _player.stop();
      if (requestId != _playRequestId) return;

      final localPath = await DownloadService.instance.getLocalPath(story.id);
      if (requestId != _playRequestId) return;

      if (localPath != null && File(localPath).existsSync()) {
        await _player.setAudioSource(
          AudioSource.file(localPath),
          initialPosition: initialPosition,
        );
        // Refresh the cache TTL so favourites that are replayed never expire
        DownloadService.instance.refreshCacheTTL(story.id, targetUrl);
      } else if (targetUrl.startsWith('http://') ||
          targetUrl.startsWith('https://')) {
        await _player.setAudioSource(
          AudioSource.uri(Uri.parse(targetUrl)),
          initialPosition: initialPosition,
        ).timeout(
          Duration(seconds: _audioTimeoutSeconds),
          onTimeout: () {
            throw TimeoutException(
              'Audio loading timed out ($_audioTimeoutSeconds s). Check network connection.',
            );
          },
        );
        // Auto-cache for offline replay (fire-and-forget, won't block playback)
        DownloadService.instance.cacheInBackground(story.id, targetUrl);
      } else {
        final cleanAsset = targetUrl.replaceFirst('asset://', '');
        await _player.setAudioSource(
          AudioSource.asset(cleanAsset),
          initialPosition: initialPosition,
        );
      }
      if (requestId != _playRequestId) return;

      // Ensure active audio session for iOS system lock-screen/Control Center
      try {
        final session = await AudioSession.instance;
        await session.setActive(true);
      } catch (_) {}

      if (requestId != _playRequestId) return;
      await _player.play();
    } catch (e) {
      if (requestId != _playRequestId) {
        debugPrint('Suppressed error for stale audio request: $e');
        return;
      }
      debugPrint('Error loading audio: $e');
      playbackError.value = 'Could not load audio. Tap to retry.';
      await _player.stop();
    }
  }

  /// Cancel current loading or audio playback immediately.
  Future<void> cancelLoading() async {
    _playRequestId++;
    playbackError.value = null;
    await _player.stop();
  }

  // ── Playlist Auto-Play ──

  List<Story> _playlistQueue = [];
  int _currentQueueIndex = -1;
  final ValueNotifier<bool> autoPlayEnabled = ValueNotifier(true);
  final ValueNotifier<int?> autoPlayCountdown = ValueNotifier(null);
  Timer? _autoPlayTimer;

  /// Load a playlist queue and start playing from the given index.
  Future<void> playPlaylist(
    List<Story> stories, {
    int startIndex = 0,
    Playlist? playlist,
  }) async {
    _playlistQueue = List.from(stories);
    playlistQueueNotifier.value = List.from(stories);
    _currentQueueIndex = startIndex;
    currentQueueIndexNotifier.value = startIndex;
    currentPlaylist.value = playlist;

    if (stories.isNotEmpty && startIndex < stories.length) {
      await playStory(
        stories[startIndex],
        playlist: playlist,
        keepPlaylistContext: true,
      );
    }
  }

  /// Start a 5-second countdown before playing the next story.
  void _startAutoPlayCountdown() {
    _cancelAutoPlay();

    autoPlayCountdown.value = 5;
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = (autoPlayCountdown.value ?? 0) - 1;
      if (remaining <= 0) {
        timer.cancel();
        autoPlayCountdown.value = null;
        _playNext();
      } else {
        autoPlayCountdown.value = remaining;
      }
    });
  }

  /// Skip countdown and play next immediately.
  void skipToNext() {
    _cancelAutoPlay();
    _playNext();
  }

  /// Cancel auto-play countdown.
  void cancelAutoPlay() {
    _cancelAutoPlay();
  }

  void _cancelAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
    autoPlayCountdown.value = null;
  }

  void toggleRepeatMode() {
    switch (repeatMode.value) {
      case BedtimeRepeatMode.off:
        repeatMode.value = BedtimeRepeatMode.all;
        _player.setLoopMode(LoopMode.off);
        break;
      case BedtimeRepeatMode.all:
        repeatMode.value = BedtimeRepeatMode.one;
        _player.setLoopMode(LoopMode.one);
        break;
      case BedtimeRepeatMode.one:
        repeatMode.value = BedtimeRepeatMode.off;
        _player.setLoopMode(LoopMode.off);
        break;
    }
  }

  void _playNext() {
    if (_playlistQueue.isEmpty) return;

    if (_currentQueueIndex + 1 < _playlistQueue.length) {
      _currentQueueIndex++;
      currentQueueIndexNotifier.value = _currentQueueIndex;
      playStory(
        _playlistQueue[_currentQueueIndex],
        keepPlaylistContext: true,
      );
    } else if (repeatMode.value == BedtimeRepeatMode.all) {
      _currentQueueIndex = 0;
      currentQueueIndexNotifier.value = 0;
      playStory(
        _playlistQueue[0],
        keepPlaylistContext: true,
      );
    } else if (_playlistQueue.length == 1) {
      playStory(
        _playlistQueue[0],
        keepPlaylistContext: true,
      );
    }
  }

  /// Play previous story in queue.
  void playPrevious() {
    if (_playlistQueue.isEmpty) return;

    if (_player.position.inSeconds > 3) {
      // If played more than 3 seconds, replay from start of current track
      _player.seek(Duration.zero);
      _player.play();
      return;
    }
    if (_currentQueueIndex > 0) {
      _currentQueueIndex--;
      currentQueueIndexNotifier.value = _currentQueueIndex;
      playStory(
        _playlistQueue[_currentQueueIndex],
        keepPlaylistContext: true,
      );
    } else if (repeatMode.value == BedtimeRepeatMode.all) {
      _currentQueueIndex = _playlistQueue.length - 1;
      currentQueueIndexNotifier.value = _currentQueueIndex;
      playStory(
        _playlistQueue[_currentQueueIndex],
        keepPlaylistContext: true,
      );
    } else {
      // Restart current story
      _player.seek(Duration.zero);
      _player.play();
    }
  }

  bool get hasNext =>
      _currentQueueIndex + 1 < _playlistQueue.length ||
      (repeatMode.value == BedtimeRepeatMode.all && _playlistQueue.length > 1);
  bool get hasPrevious =>
      _currentQueueIndex > 0 ||
      _playlistQueue.length > 1 ||
      (repeatMode.value == BedtimeRepeatMode.all && _playlistQueue.isNotEmpty);

  // ── Video Story Playback Coordination ──

  VideoPlayerController? _activeVideoController;
  VideoPlayerController? get activeVideoController => _activeVideoController;

  void registerVideoController(
    VideoPlayerController controller, {
    required Story story,
  }) {
    if (_activeVideoController != null && _activeVideoController != controller) {
      final old = _activeVideoController!;
      old.removeListener(_onVideoControllerUpdate);
      try {
        old.pause();
        old.dispose();
      } catch (_) {}
    }

    _activeVideoController = controller;
    currentStory.value = story;
    isPlaying.value = controller.value.isPlaying;

    controller.removeListener(_onVideoControllerUpdate);
    controller.addListener(_onVideoControllerUpdate);
    _onVideoControllerUpdate();

    final resolvedCover = resolveStorageUrl(story.coverImageUrl);
    final artUri = (Platform.isIOS &&
            (resolvedCover.startsWith('http://') ||
                resolvedCover.startsWith('https://') ||
                resolvedCover.startsWith('file://')))
        ? Uri.tryParse(resolvedCover)
        : null;

    try {
      _audioHandler.mediaItem.add(
        MediaItem(
          id: story.id,
          title: story.title,
          artist: story.narrator,
          album: 'Storytime with Barbara',
          artUri: artUri,
          duration: controller.value.duration.inSeconds > 0
              ? controller.value.duration
              : Duration(seconds: story.duration),
        ),
      );
    } catch (e) {
      debugPrint('Error publishing video mediaItem metadata: $e');
    }

    _broadcastVideoState();
  }

  void _onVideoControllerUpdate() {
    if (_activeVideoController == null) return;
    final ctrl = _activeVideoController!;
    if (isPlaying.value != ctrl.value.isPlaying) {
      isPlaying.value = ctrl.value.isPlaying;
    }
    final buffered = ctrl.value.buffered.isNotEmpty
        ? ctrl.value.buffered.last.end
        : Duration.zero;
    _positionDataSubject.add(
      PositionData(ctrl.value.position, buffered, ctrl.value.duration),
    );
  }

  void updateVideoPlaybackState(bool isPlayingNow) {
    isPlaying.value = isPlayingNow;
    _broadcastVideoState();
  }

  void _broadcastVideoState() {
    if (_activeVideoController == null) return;
    final ctrl = _activeVideoController!;
    final playing = ctrl.value.isPlaying;
    try {
      _audioHandler.playbackState.add(
        PlaybackState(
          controls: [
            MediaControl.rewind,
            if (playing) MediaControl.pause else MediaControl.play,
            MediaControl.fastForward,
            MediaControl.stop,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
            MediaAction.play,
            MediaAction.pause,
            MediaAction.playPause,
            MediaAction.stop,
            MediaAction.fastForward,
            MediaAction.rewind,
          },
          androidCompactActionIndices: const [0, 1, 2],
          processingState: ctrl.value.isInitialized
              ? AudioProcessingState.ready
              : AudioProcessingState.buffering,
          playing: playing,
          updatePosition: ctrl.value.position,
          bufferedPosition: ctrl.value.buffered.isNotEmpty
              ? ctrl.value.buffered.last.end
              : Duration.zero,
          speed: playing ? 1.0 : 0.0,
        ),
      );
    } catch (e) {
      debugPrint('Error broadcasting video state: $e');
    }
  }

  void unregisterVideoController() {
    if (_activeVideoController != null) {
      _activeVideoController!.removeListener(_onVideoControllerUpdate);
      _activeVideoController = null;
    }
  }

  Future<void> transitionFromVideoToAudio(
    Story story, {
    required Duration position,
  }) async {
    unregisterVideoController();
    await playStory(story, initialPosition: position);
  }

  void registerPausedVideoStory(Story story, {Duration position = Duration.zero}) {
    unregisterVideoController();
    currentStory.value = story;
    isPlaying.value = false;
  }

  /// Stop all audio/video playback and reset current story.
  Future<void> stopPlayback() async {
    // Clear UI state synchronously so MiniPlayer is destroyed immediately
    currentStory.value = null;
    currentPlaylist.value = null;
    isPlaying.value = false;
    isVideoPlayerFullScreen.value = false;
    _positionDataSubject.add(
      PositionData(Duration.zero, Duration.zero, Duration.zero),
    );

    if (_activeVideoController != null) {
      final ctrl = _activeVideoController!;
      _activeVideoController = null;
      ctrl.removeListener(_onVideoControllerUpdate);
      try {
        await ctrl.pause();
        await ctrl.dispose();
      } catch (_) {}
    }
    await _player.stop();
    try {
      _audioHandler.playbackState.add(
        PlaybackState(
          playing: false,
          processingState: AudioProcessingState.idle,
        ),
      );
    } catch (_) {}
  }

  /// Play / pause toggle.
  void togglePlayPause() {
    if (_activeVideoController != null) {
      if (_activeVideoController!.value.isPlaying) {
        _activeVideoController!.pause();
        isPlaying.value = false;
      } else {
        _activeVideoController!.play();
        isPlaying.value = true;
      }
      _broadcastVideoState();
    } else {
      if (_player.playing) {
        _player.pause();
      } else {
        _player.play();
      }
    }
  }

  void play() {
    if (_activeVideoController != null) {
      _activeVideoController!.play();
      isPlaying.value = true;
      _broadcastVideoState();
    } else {
      _player.play();
    }
  }

  void pause() {
    if (_activeVideoController != null) {
      _activeVideoController!.pause();
      isPlaying.value = false;
      _broadcastVideoState();
    } else {
      _player.pause();
    }
  }

  void seek(Duration position) {
    if (_activeVideoController != null) {
      _activeVideoController!.seekTo(position);
      _broadcastVideoState();
    } else {
      _player.seek(position);
    }
  }

  void setLoopMode(LoopMode mode) => _player.setLoopMode(mode);

  // ── Sleep Timer ──

  /// Start a sleep timer. Pass minutes > 0 for timed, -1 for end-of-story,
  /// 0 to cancel.
  void setSleepTimer(int minutes) {
    // Cancel any existing timer
    _cancelSleepTimer();

    if (minutes == 0) {
      // Timer off
      sleepTimerMinutes.value = null;
      sleepTimerRemaining.value = null;
      return;
    }

    if (minutes == -1) {
      // End of story — listen for completion
      sleepTimerMinutes.value = -1;
      sleepTimerRemaining.value = null;
      _endOfStorySubscription?.cancel();
      _endOfStorySubscription = _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _onSleepTimerComplete();
        }
      });
      return;
    }

    // Timed sleep
    sleepTimerMinutes.value = minutes;
    final duration = Duration(minutes: minutes);
    sleepTimerRemaining.value = duration;

    // Countdown ticker (updates every second)
    _sleepCountdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        final remaining = sleepTimerRemaining.value;
        if (remaining != null && remaining.inSeconds > 0) {
          sleepTimerRemaining.value = remaining - const Duration(seconds: 1);
        }
      },
    );

    // Actual sleep timer — fade out then pause
    final fadeDelay = duration > const Duration(seconds: 10)
        ? duration - const Duration(seconds: 10)
        : Duration.zero;
    _sleepTimer = Timer(fadeDelay, () {
      _fadeOutAndPause();
    });
  }

  bool _isFadingOut = false;
  double _preFadeVolume = 1.0;

  /// Gradually reduces volume over 10 seconds, then pauses.
  Future<void> _fadeOutAndPause() async {
    _isFadingOut = true;
    const steps = 20;
    const stepDuration = Duration(milliseconds: 500);
    _preFadeVolume = _player.volume;
    
    // Fade out ambient sounds
    AmbientSoundService.instance.fadeOutAll();

    for (int i = steps; i >= 0; i--) {
      if (!_isFadingOut || !_player.playing) break;
      await _player.setVolume(_preFadeVolume * (i / steps));
      await Future.delayed(stepDuration);
    }

    if (!_isFadingOut) return;
    _isFadingOut = false;
    _player.pause();
    await _player.setVolume(_preFadeVolume); // Restore volume for next play
    _onSleepTimerComplete();
  }

  void _onSleepTimerComplete() {
    _cancelSleepTimer();
    sleepTimerMinutes.value = null;
    sleepTimerRemaining.value = null;
  }

  void _cancelSleepTimer() {
    if (_isFadingOut) {
      _isFadingOut = false;
      _player.setVolume(_preFadeVolume);
      AmbientSoundService.instance.cancelFadeOut();
    }
    _endOfStorySubscription?.cancel();
    _endOfStorySubscription = null;
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepCountdownTimer?.cancel();
    _sleepCountdownTimer = null;
  }

  /// Clean up resources.
  void dispose() {
    _cancelSleepTimer();
    _player.dispose();
  }
}

// ── AudioHandler for audio_service native lock-screen / Control Center integration ──

class _BedtimeAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player;

  _BedtimeAudioHandler(this._player) {
    _player.playbackEventStream.listen(
      _broadcastState,
      onError: (e, st) => debugPrint('playbackEventStream error: $e'),
    );
    _player.playerStateStream.listen(
      (_) => _broadcastState(_player.playbackEvent),
      onError: (e, st) => debugPrint('playerStateStream error: $e'),
    );
    _player.durationStream.listen(
      (dur) {
        if (mediaItem.value != null && dur != null) {
          mediaItem.add(mediaItem.value!.copyWith(duration: dur));
        }
      },
      onError: (e, st) => debugPrint('durationStream error: $e'),
    );
  }

  void _broadcastState([PlaybackEvent? event]) {
    final playing = _player.playing;
    final processingState = const {
      ProcessingState.idle: AudioProcessingState.idle,
      ProcessingState.loading: AudioProcessingState.loading,
      ProcessingState.buffering: AudioProcessingState.buffering,
      ProcessingState.ready: AudioProcessingState.ready,
      ProcessingState.completed: AudioProcessingState.completed,
    }[_player.processingState] ?? AudioProcessingState.idle;

    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.rewind,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.fastForward,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.play,
          MediaAction.pause,
          MediaAction.playPause,
          MediaAction.stop,
          MediaAction.fastForward,
          MediaAction.rewind,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: processingState,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: playing ? 1.0 : 0.0,
        queueIndex: event?.currentIndex,
      ),
    );
  }

  @override
  Future<void> play() async {
    if (AudioPlayerService.instance._activeVideoController != null) {
      await AudioPlayerService.instance._activeVideoController!.play();
      AudioPlayerService.instance.isPlaying.value = true;
      AudioPlayerService.instance._broadcastVideoState();
    } else {
      await _player.play();
    }
  }

  @override
  Future<void> pause() async {
    if (AudioPlayerService.instance._activeVideoController != null) {
      await AudioPlayerService.instance._activeVideoController!.pause();
      AudioPlayerService.instance.isPlaying.value = false;
      AudioPlayerService.instance._broadcastVideoState();
    } else {
      await _player.pause();
    }
  }

  @override
  Future<void> seek(Duration position) async {
    if (AudioPlayerService.instance._activeVideoController != null) {
      await AudioPlayerService.instance._activeVideoController!.seekTo(position);
      AudioPlayerService.instance._broadcastVideoState();
    } else {
      await _player.seek(position);
    }
  }

  @override
  Future<void> stop() async {
    await AudioPlayerService.instance.stopPlayback();
    return super.stop();
  }

  @override
  Future<void> fastForward() {
    if (AudioPlayerService.instance._activeVideoController != null) {
      final ctrl = AudioPlayerService.instance._activeVideoController!;
      final newPos = ctrl.value.position + const Duration(seconds: 15);
      return ctrl.seekTo(newPos);
    }
    return _player.seek(_player.position + const Duration(seconds: 15));
  }

  @override
  Future<void> rewind() {
    if (AudioPlayerService.instance._activeVideoController != null) {
      final ctrl = AudioPlayerService.instance._activeVideoController!;
      final newPos = ctrl.value.position - const Duration(seconds: 15);
      final clamped = newPos < Duration.zero ? Duration.zero : newPos;
      return ctrl.seekTo(clamped);
    }
    return _player.seek(_player.position - const Duration(seconds: 15));
  }

  @override
  Future<void> skipToNext() async {
    AudioPlayerService.instance.skipToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    AudioPlayerService.instance.playPrevious();
  }
}
