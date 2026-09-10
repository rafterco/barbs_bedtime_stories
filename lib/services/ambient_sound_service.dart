import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AmbientSound {
  final String id;
  final String name;
  final String emoji;
  final String assetPath;
  double volume;
  bool isActive;

  AmbientSound({
    required this.id,
    required this.name,
    required this.emoji,
    required this.assetPath,
    this.volume = 0.5,
    this.isActive = false,
  });
}

class AmbientSoundService {
  AmbientSoundService._();
  static final AmbientSoundService instance = AmbientSoundService._();

  final List<AmbientSound> _sounds = [
    AmbientSound(id: 'rain', name: 'Rain', emoji: '🌧️', assetPath: 'assets/audio/ambient/rain.m4a'),
    AmbientSound(id: 'ocean', name: 'Ocean Waves', emoji: '🌊', assetPath: 'assets/audio/ambient/ocean.m4a'),
    AmbientSound(id: 'white_noise', name: 'White Noise', emoji: '📻', assetPath: 'assets/audio/ambient/white_noise.m4a'),
    AmbientSound(id: 'heartbeat', name: 'Heartbeat', emoji: '💓', assetPath: 'assets/audio/ambient/heartbeat.m4a'),
    AmbientSound(id: 'wind', name: 'Wind', emoji: '🍃', assetPath: 'assets/audio/ambient/wind.m4a'),
    AmbientSound(id: 'fireplace', name: 'Fireplace', emoji: '🔥', assetPath: 'assets/audio/ambient/fireplace.m4a'),
    AmbientSound(id: 'thunder', name: 'Thunder', emoji: '⛈️', assetPath: 'assets/audio/ambient/thunder.m4a'),
  ];

  final Map<String, AudioPlayer> _players = {};
  
  final ValueNotifier<List<AmbientSound>> activeSounds = ValueNotifier([]);

  List<AmbientSound> get allSounds => _sounds;

  Future<void> toggleSound(String id) async {
    final soundIndex = _sounds.indexWhere((s) => s.id == id);
    if (soundIndex == -1) return;
    
    final sound = _sounds[soundIndex];

    if (sound.isActive) {
      // Stop and remove immediately
      sound.isActive = false;
      _updateActiveSounds();
      
      final player = _players.remove(id);
      if (player != null) {
        try {
          await player.stop();
          await player.dispose();
        } catch (_) {}
      }
    } else {
      // Add and play (max 3 concurrent)
      if (_sounds.where((s) => s.isActive).length >= 3) return;
      
      sound.isActive = true;
      _updateActiveSounds(); // Optimistic update so UI highlights immediately
      
      final player = AudioPlayer();
      _players[id] = player;
      
      try {
        await player.setAsset(sound.assetPath);
        await player.setVolume(sound.volume);
        await player.setLoopMode(LoopMode.one);
        // Start playback without blocking toggleSound
        player.play().catchError((e) {
          debugPrint('Ambient play error for $id: $e');
        });
      } catch (e) {
        debugPrint('Error loading ambient sound $id (${sound.assetPath}): $e');
        sound.isActive = false;
        _players.remove(id);
        _updateActiveSounds();
        try {
          await player.stop();
          await player.dispose();
        } catch (_) {}
      }
    }
  }

  void setVolume(String id, double volume) {
    final soundIndex = _sounds.indexWhere((s) => s.id == id);
    if (soundIndex != -1) {
      _sounds[soundIndex].volume = volume;
      _players[id]?.setVolume(volume);
      _updateActiveSounds();
    }
  }

  /// Pause all active ambient sounds without clearing active state
  void pauseActiveSounds() {
    for (var player in _players.values) {
      try {
        player.pause();
      } catch (_) {}
    }
  }

  /// Resume all active ambient sounds
  void resumeActiveSounds() {
    for (var entry in _players.entries) {
      final sound = _sounds.firstWhere(
        (s) => s.id == entry.key,
        orElse: () => AmbientSound(id: '', name: '', emoji: '', assetPath: '', isActive: false),
      );
      if (sound.isActive) {
        try {
          entry.value.play();
        } catch (_) {}
      }
    }
  }

  Future<void> stopAll() async {
    for (var sound in _sounds) {
      sound.isActive = false;
    }
    
    for (var player in _players.values) {
      try {
        await player.stop();
        await player.dispose();
      } catch (_) {}
    }
    _players.clear();
    _updateActiveSounds();
  }

  bool _isFadingOut = false;

  /// Cancel an ongoing volume fade out and restore configured sound volumes.
  void cancelFadeOut() {
    _isFadingOut = false;
    for (var entry in _players.entries) {
      final sound = _sounds.cast<AmbientSound?>().firstWhere(
            (s) => s?.id == entry.key,
            orElse: () => null,
          );
      if (sound != null && sound.isActive) {
        try {
          entry.value.setVolume(sound.volume);
        } catch (_) {}
      }
    }
  }

  Future<void> fadeOutAll() async {
    _isFadingOut = true;
    const steps = 20;
    const stepDuration = Duration(milliseconds: 500);

    for (int i = steps; i >= 0; i--) {
      if (!_isFadingOut) return;
      for (var entry in _players.entries) {
        final sound = _sounds.cast<AmbientSound?>().firstWhere(
              (s) => s?.id == entry.key,
              orElse: () => null,
            );
        if (sound != null && sound.isActive) {
          try {
            await entry.value.setVolume(sound.volume * (i / steps));
          } catch (_) {}
        }
      }
      await Future.delayed(stepDuration);
    }
    
    if (!_isFadingOut) return;
    _isFadingOut = false;
    await stopAll();
  }

  void _updateActiveSounds() {
    activeSounds.value = _sounds.where((s) => s.isActive).toList();
  }
}
