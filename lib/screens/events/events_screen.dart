import 'package:flutter/material.dart';
// import 'package:unstop_clone/screens/HomePage.dart';
// import 'package:unstop_clone/screens/home_screen.dart';
import 'package:unstop_clone/screens/events/event_host_screen.dart';
import 'package:unstop_clone/screens/events/events_hosted.dart';
import 'package:unstop_clone/screens/events/explore_events_screen.dart';
import 'package:unstop_clone/screens/events/favourite_events.dart';
import 'package:unstop_clone/screens/events/applied_events.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key, required this.homeIndex});
  final void Function(int index) homeIndex;

  @override
  _EventsScreenState createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  int _currentIndex = 0;

  void _onTappedItem(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      ExploreEventsScreen(),
      AppliedEvents(),
      FavouriteEvents(),
      EventHostScreen(switchScreen: _onTappedItem),
      EventsHosted(),
    ];

    return Scaffold(
        appBar: AppBar(
          title: _currentIndex == 1
              ? const Text('Registered Events')
              : _currentIndex == 2
                  ? const Text('Favourite Events')
                  : _currentIndex == 3
                      ? const Text('Create Events')
                      : _currentIndex == 4
                          ? const Text('Your Events')
                          : const Text('Events'),
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
              icon: Icon(Icons.event),
              label: 'Applied',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Wishlist',
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

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Explore Events"),
    );
  }
}

class AppliedEventsScreen extends StatelessWidget {
  const AppliedEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Your Applied Events"),
    );
  }
}

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Your Wishlist"),
    );
  }
}

// class HostScreen extends StatelessWidget {
//   const HostScreen({super.key});
//   final String imagePath = 'assets/event_placeholder.jpg';
//   @override
//   Widget build(BuildContext context) {
//     return EventHostScreen(switchScreen: _onTappedItem,);
//   }
// }
