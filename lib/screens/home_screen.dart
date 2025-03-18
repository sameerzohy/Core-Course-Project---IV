import 'package:flutter/material.dart';
import 'package:unstop_clone/screens/HomePage.dart';
import 'package:unstop_clone/screens/events/events_screen.dart';
import 'package:unstop_clone/screens/hackathons/hackathon_homescreen.dart';
import 'package:unstop_clone/screens/workshops/workshop_home.dart';
import 'package:unstop_clone/community_forum.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // State variable to track selected tab

  // List of screens to avoid recursive widget creation

  void _onTappedItem(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> screens = [
      HomePage(), // Instead of returning HomeScreen again
      EventsScreen(homeIndex: _onTappedItem),
      WorkshopHomescreen(homeIndex: _onTappedItem),
      HackathonHomescreen(homeIndex: _onTappedItem),
      CommunityForumScreen(homeIndex: _onTappedItem),
    ];

    return Scaffold(
      bottomNavigationBar: _selectedIndex == 0
          ? BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedIndex, // Highlight correct tab
              onTap: _onTappedItem,
              selectedItemColor: Colors.blue,
              unselectedItemColor: Colors.grey,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.event), label: 'Events'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.handyman), label: 'Workshops'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.emoji_events), label: 'Hackathons'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.forum), label: 'Community Forums'),
              ],
            )
          : null,
      body: screens[_selectedIndex], // Reference screen from list
    );
  }
}

// Create a separate widget for HomePage to avoid recursive call
// Other screens remain the same

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Profile Screen'));
  }
}
