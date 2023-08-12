import 'package:barbs_bedtime_stories/screens/screens.dart';
import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

import '../models/story_model.dart';

class StoryCard extends StatelessWidget {
  const StoryCard({
    Key? key,
    required this.stories,
  }) : super(key: key);

  final List<Story> stories;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.0),
                image: DecorationImage(
                  image: AssetImage(
                    stories[0].coverUrl,
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              height: 25,
              width: MediaQuery.of(context).size.width * 0.37,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.0),
                color: Colors.white.withOpacity(0.65),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FutureBuilder(
                          future: Future.delayed(const Duration(seconds: 3)),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              // Show a placeholder widget while waiting for the delay
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(10, 3, 0, 0),
                                  child: Text(
                                    stories[0].title,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                      color: Colors.deepPurple,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              // After the delay, return the Marquee widget to start scrolling
                              return Expanded(
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(0, 3, 0, 0),
                                  child: Marquee(
                                    text: stories[0].title,
                                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                      color: Colors.deepPurple,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    scrollAxis: Axis.horizontal,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    blankSpace: 150.0,
                                    velocity: 70.0,
                                    pauseAfterRound: const Duration(seconds: 3),
                                    startPadding: 7.0,
                                    accelerationDuration: const Duration(seconds: 2),
                                    accelerationCurve: Curves.linear,
                                    decelerationDuration: const Duration(milliseconds: 500),
                                    decelerationCurve: Curves.easeOut,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.play_circle,
                    color: Colors.deepPurple,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => StoryScreen(stories)),
        );
      },
    );
  }

  bool _willTextOverflow({required String text, required TextStyle style}) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: 100);

    return textPainter.didExceedMaxLines;
  }
}
