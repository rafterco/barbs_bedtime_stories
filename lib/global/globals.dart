import 'dart:collection';

import '../models/playlist_model.dart';
import '../models/story_model.dart';

class Global {
  static Set<Story> stories = {};
  static Set<Playlist> playLists = {};
  static Map<String, Set<Story>> playListStoriesToStory = HashMap<String, Set<Story>>();
}

