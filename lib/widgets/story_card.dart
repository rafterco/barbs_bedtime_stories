import 'package:barbs_bedtime_stories/screens/screens.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
              height: 50,
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
                        Text(
                          stories[0].title,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          stories[0].description,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
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
}
