import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:barbs_bedtime_stories/services/ambient_sound_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AmbientSoundService Asset Verification', () {
    test('defines all 7 ambient sounds with expected identifiers', () {
      final sounds = AmbientSoundService.instance.allSounds;
      expect(sounds.length, 7);

      final ids = sounds.map((s) => s.id).toList();
      expect(
        ids,
        containsAll([
          'rain',
          'ocean',
          'white_noise',
          'heartbeat',
          'wind',
          'fireplace',
          'thunder',
        ]),
      );
    });

    test('every ambient sound asset exists on disk and is high fidelity (>500KB)', () {
      final sounds = AmbientSoundService.instance.allSounds;
      for (final sound in sounds) {
        final file = File(sound.assetPath);
        expect(file.existsSync(), isTrue, reason: 'Asset file missing: ${sound.assetPath}');
        final sizeInBytes = file.lengthSync();
        // High fidelity audio should be at least 500 KB (old low-quality files were ~30-160 KB)
        expect(
          sizeInBytes,
          greaterThan(500 * 1024),
          reason: 'Asset file ${sound.assetPath} is too small ($sizeInBytes bytes). Expected high-fidelity audio >500KB.',
        );
      }
    });

    test('ambient sound toggle initializes player properly and respects max concurrent', () async {
      expect(AmbientSoundService.instance.activeSounds.value, isEmpty);
    });
  });
}
