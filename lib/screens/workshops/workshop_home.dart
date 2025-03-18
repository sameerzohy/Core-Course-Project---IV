// import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:unstop_clone/screens/workshops/hosted_workshops.dart';
import 'package:unstop_clone/screens/workshops/workshop_explorer.dart';
import 'package:unstop_clone/screens/workshops/applied_workshops.dart';
import 'package:unstop_clone/screens/workshops/ai_chat.dart';
// import 'package:unstop_clone/screens/workshops/community_forum.dart';
import 'package:unstop_clone/screens/workshops/workshop_host.dart';
// import 'package:unstop_clone/screens/workshops/workshop_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkshopHomescreen extends StatefulWidget {
  const WorkshopHomescreen({super.key, required this.homeIndex});
  final void Function(int index) homeIndex;

  @override
  State<WorkshopHomescreen> createState() => _WorkshopHomescreenState();
}

class _WorkshopHomescreenState extends State<WorkshopHomescreen> {
  int _currentIndex = 0;

  void _onTappedItem(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      ExploreWorkshopsScreen(),
      AppliedWorkshops(),
      AIChat(
        userId: FirebaseAuth.instance.currentUser!.uid,
      ),
      WorkshopHostScreen(switchScreen: _onTappedItem),
      WorkshopsHosted(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: _currentIndex == 0
            ? const Text('Workshops')
            : _currentIndex == 1
                ? const Text('Applied Workshops')
                : _currentIndex == 2
                    ? const Text('AI Chat')
                    : _currentIndex == 3
                        ? const Text('Community Forum')
                        : const Text('Your Workshops'),
        actions: [
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
            icon: Icon(Icons.event_note),
            label: 'Applied',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: 'AI Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum),
            label: 'Host',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Hosted',
          )
        ],
      ),
    );
  }
}
