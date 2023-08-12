import 'package:barbs_bedtime_stories/widgets/story_card.dart';
import 'package:flutter/material.dart';
import '../models/story_model.dart';
import '../screens/story_screen.dart';

class StorySearchCard extends StatelessWidget {
  const StorySearchCard({
    Key? key,
    required this.story,
  }) : super(key: key);

  final Story story;

  @override
  Widget build(BuildContext context) {
    List<Story> stories = [story];
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => StoryScreen(stories)),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 5, 0, 5),
        height: 75,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3), // Shadow color
              spreadRadius: 3, // Spread radius
              blurRadius: 1, // Blur radius
              offset: const Offset(0, 1), // Offset in the x and y direction
            ),
          ],
          color: Colors.deepPurple.shade800.withOpacity(0.6),
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.25,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.0),
                image: DecorationImage(
                  image: AssetImage(
                    story.coverUrl,
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10,),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15.0),
                      child: Text(
                        story.title,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge!
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(story.description,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium!),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StoryScreen(stories)),
                );
              },
              icon: const Icon(
                Icons.play_circle,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
