import 'package:flutter/material.dart';
import 'package:unstop_clone/screens/hackathons/applied_hackathons.dart';
import 'package:unstop_clone/screens/hackathons/hackathon_notifcations.dart';
import 'package:unstop_clone/screens/hackathons/hackathon_team.dart';
// import 'package:unstop_clone/screens/HomePage.dart';
// import 'package:unstop_clone/screens/home_screen.dart';
import 'package:unstop_clone/screens/hackathons/home_page.dart';
import 'package:unstop_clone/screens/hackathons/host_hackathon.dart';
import 'package:unstop_clone/screens/hackathons/hosted_hackathon.dart';

class HackathonHomescreen extends StatefulWidget {
  const HackathonHomescreen({super.key, required this.homeIndex});
  final void Function(int index) homeIndex;

  @override
  State<HackathonHomescreen> createState() => _HackathonHomescreenState();
}

class _HackathonHomescreenState extends State<HackathonHomescreen> {
  int _currentIndex = 0;

  void _onTappedItem(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      ExploreHackathonsScreen(),
      AppliedHackathons(),
      HackathonTeam(),
      HackathonHostScreen(switchScreen: _onTappedItem),
      HostedHackathon(),
    ];

    return Scaffold(
        appBar: AppBar(
          title: _currentIndex == 1
              ? const Text('Applied Hackathons')
              : _currentIndex == 2
                  ? const Text('Your Team')
                  : _currentIndex == 3
                      ? const Text('Create Hackathons')
                      : _currentIndex == 4
                          ? const Text('Your Hackathons')
                          : const Text('Hackatons'),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HackathonNotifications(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                widget.homeIndex(0);
              },
            )
          ],
        ),
        body: screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          onTap: _onTappedItem,
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event),
              label: 'Applied',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group),
              label: 'Your Team',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_box),
              label: 'Host',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event),
              label: 'Hosted',
            )
          ],
        ));
  }
}
