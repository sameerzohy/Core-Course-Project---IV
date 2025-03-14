import 'package:flutter/material.dart';
import 'package:unstop_clone/screens/HomePage.dart';
import 'package:unstop_clone/screens/events/events_screen.dart';
import 'package:unstop_clone/screens/hackathons/hackathon_homescreen.dart';

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
      WorkshopsScreen(),
      HackathonHomescreen(homeIndex: _onTappedItem),
      ProfileScreen(),
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
                    icon: Icon(Icons.person), label: 'Profile'),
              ],
            )
          : null,
      body: screens[_selectedIndex], // Reference screen from list
    );
  }
}

// Create a separate widget for HomePage to avoid recursive call
// Other screens remain the same

class WorkshopsScreen extends StatelessWidget {
  const WorkshopsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Workshops Screen'));
  }
}

class HackathonsScreen extends StatelessWidget {
  const HackathonsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Hackathons Screen'));
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Profile Screen'));
  }
}
