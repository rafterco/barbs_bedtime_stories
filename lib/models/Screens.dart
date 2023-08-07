
import 'package:flutter/material.dart';

import '../screens/favourites.dart';
import '../screens/home_screen.dart';
import '../screens/search_screen.dart';

class Screens {
  static final List<Widget> screens = [
    HomeScreen(),
    const FavouritesScreen(),
    const SearchScreen(),
    HomeScreen(),
    HomeScreen(),
  ];
}
