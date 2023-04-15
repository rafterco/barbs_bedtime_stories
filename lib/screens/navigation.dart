import 'package:barbs_bedtime_stories/screens/favourites.dart';
import 'package:barbs_bedtime_stories/screens/search_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import '../models/Screens.dart';

class Navigation extends StatefulWidget {
  const Navigation({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Screens.screens.elementAt(_index),
      bottomNavigationBar: Container(
        color: Colors.black,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20.0),
          child: GNav(
            onTabChange: (index) {
              setState(() {
                _index = index;
              });
            },
            color: Colors.white,
            tabBackgroundColor: Colors.grey.shade800,
            gap: 8,
            backgroundColor: Colors.black,
            activeColor: Colors.white,
            padding: const EdgeInsets.all(10),
            tabs: const [
              GButton(
                icon: Icons.home,
                text: 'Home',
              ),
              GButton(
                icon: Icons.favorite_border,
                text: 'Favourites',
              ),
              GButton(
                icon: Icons.search,
                text: 'Search',
              ),
            /*  GButton(
                icon: Icons.settings,
                text: 'Settings',
              ),
              GButton(
                icon: Icons.account_circle,
                text: 'Account',
              ),*/
            ],
          ),
        ),
      ),
    );
  }
}
