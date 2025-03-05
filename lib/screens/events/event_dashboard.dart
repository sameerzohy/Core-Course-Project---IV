import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unstop_clone/screens/events/event_update_screen.dart';

class EventDashBoard extends StatefulWidget {
  const EventDashBoard({super.key, required this.eventId});

  final String eventId;

  @override
  State<EventDashBoard> createState() => _EventDashBoardState();
}

class _EventDashBoardState extends State<EventDashBoard> {
  void switchScreen(index) {
    setState(() {
      _currentIndex = index;
    });
  }

  int _currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    List<Widget> screens = [
      EventsDetailsScreen(eventId: widget.eventId),
      EventUpdateScreen(eventId: widget.eventId, switchScreen: switchScreen),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text('Event Dashboard'),
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          switchScreen(index);
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.details), label: 'Details'),
          BottomNavigationBarItem(icon: Icon(Icons.update), label: 'Update'),
        ],
      ),
    );
  }
}

class EventsDetailsScreen extends StatefulWidget {
  const EventsDetailsScreen({super.key, required this.eventId});

  final String eventId;

  @override
  State<EventsDetailsScreen> createState() => _EventsDetailsScreenState();
}

class _EventsDetailsScreenState extends State<EventsDetailsScreen> {
  final userId = FirebaseAuth.instance.currentUser!.uid;
  final user = FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .get();
  Future<Map<String, dynamic>?> getEventDetails(String eventId) async {
    try {
      var response = await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .get();
      return response.data();
    } catch (e) {
      debugPrint("Error fetching event details: $e");
      return null;
    }
  }

  bool registeredStatus(eventDetails) {
    return !eventDetails.containsKey('registered_members') ||
        !eventDetails['registered_members'].contains(userId);
  }

  // void _addMember(userId, eventDetails) async {
  //   // if (eventDetails['maxParticipants'] -
  //   //         eventDetails['registerd_members'].length <=
  //   //     0) return;
  //   if (eventDetails.containsKey('registered_members') &&
  //       (eventDetails['maxParticipants'] -
  //               eventDetails['registered_members'].length <=
  //           0)) return;
  //   await FirebaseFirestore.instance
  //       .collection('events')
  //       .doc(widget.eventId)
  //       .update({
  //     'registered_members': FieldValue.arrayUnion([userId])
  //   });

  //   await FirebaseFirestore.instance.collection('users').doc(userId).update({
  //     'registered_events': FieldValue.arrayUnion([widget.eventId])
  //   });
  // }

  // void _removeMember(String userId) async {
  //   await FirebaseFirestore.instance
  //       .collection('events')
  //       .doc(widget.eventId)
  //       .update({
  //     'registered_members': FieldValue.arrayRemove([userId])
  //   });

  //   await FirebaseFirestore.instance.collection('events').doc(userId).update({
  //     'registered_events': FieldValue.arrayRemove([widget.eventId])
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: getEventDetails(widget.eventId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text("Event details not found."));
        }

        var eventDetails = snapshot.data!;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Banner Image
              eventDetails['eventImage'] != null
                  ? Image.network(
                      eventDetails['eventImage'],
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 250,
                      color: Colors.grey[300],
                      child: const Center(child: Text('No Image Available')),
                    ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event Name
                    Text(
                      eventDetails['eventName'] ?? 'Unnamed Event',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 10),

                    // Event Description
                    Text(
                      eventDetails['eventDescription'] ??
                          'No description available.',
                      style: const TextStyle(fontSize: 16),
                    ),

                    const SizedBox(height: 20),

                    // Event Date & Time
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          "Date: ${eventDetails['eventDate'] ?? 'Unknown'}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          "Time: ${eventDetails['eventTime'] ?? 'Unknown'}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Location
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            eventDetails['eventLocation'] ??
                                'Location not specified',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Event Type
                    Row(
                      children: [
                        const Icon(Icons.category, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          "Type: ${eventDetails['eventType'] ?? 'General'}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Event Fee
                    Row(
                      children: [
                        const Icon(Icons.money, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          eventDetails['eventFee'] == 0
                              ? "Free Event"
                              : "Fee: ₹${eventDetails['eventFee']}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Payment Status
                    Row(
                      children: [
                        const Icon(Icons.payment, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          "Payment: ${eventDetails['eventPayment'] ?? 'Unpaid'}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Organizer Details
                    const Divider(thickness: 1),
                    const SizedBox(height: 10),
                    const Text(
                      "Organizer Information",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Icon(Icons.person, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          "Name: ${eventDetails['organizerName'] ?? 'Unknown'}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Icon(Icons.email, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          "Email: ${eventDetails['organizerEmail'] ?? 'Not available'}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Icon(Icons.phone, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          "Contact: ${eventDetails['organizerContact'] ?? 'Not available'}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Maximum Participants
                    Row(
                      children: [
                        const Icon(Icons.people, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          "Max Participants: ${eventDetails['maxParticipants'] ?? 'N/A'}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.people, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          "Avaliable slots: ${eventDetails.containsKey('registered_members') ? eventDetails['maxParticipants'] - eventDetails['registered_members'].length ?? 'N/A' : eventDetails['maxParticipants']}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    // Register Button
                    const Divider(thickness: 1),
                    // const SizedBox(height: 10),
                    Container(
                      margin: EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Registered Members",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          ListView.builder(
                            shrinkWrap:
                                true, // This makes ListView take only the required space
                            physics:
                                NeverScrollableScrollPhysics(), // Prevents nested scrolling issues
                            itemCount:
                                eventDetails.containsKey('registered_members')
                                    ? eventDetails['registered_members'].length
                                    : 0,
                            itemBuilder: (context, index) {
                              return FutureBuilder<Map<String, dynamic>>(
                                future: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(eventDetails['registered_members']
                                        [index])
                                    .get()
                                    .then((snapshot) => snapshot.data()
                                        as Map<String, dynamic>),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 5),
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  if (snapshot.hasError) {
                                    return Text("Error: ${snapshot.error}");
                                  }
                                  if (!snapshot.hasData ||
                                      snapshot.data == null) {
                                    return Text("No Data Found");
                                  }

                                  // Extract user data
                                  Map<String, dynamic> userData =
                                      snapshot.data!;

                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 5),
                                    child: Text(
                                        "${index + 1}) ${userData['name']}"),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
