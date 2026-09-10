import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barbs_bedtime_stories/features/player/video_story_player_screen.dart';

void main() {
  testWidgets('VideoStoryPlayerScreen top header renders without overflow on 320px screen', (tester) async {
    tester.view.physicalSize = const Size(320 * 2, 568 * 2);
    tester.view.devicePixelRatio = 2.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: VideoStoryPlayerScreen(
          videoUrl: 'https://example.com/video.mp4',
          title: 'A Day Closes in the Woods',
          narrator: 'Barbara',
          onSwitchToAudio: () {},
          onClose: () {},
        ),
      ),
    );

    await tester.pump();

    expect(find.byTooltip('Minimize'), findsOneWidget);
    expect(find.text('Storytime with Barbara'), findsOneWidget);
    expect(find.text('Audio'), findsOneWidget);
    expect(find.byTooltip('Close'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}
