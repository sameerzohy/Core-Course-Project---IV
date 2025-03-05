import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:unstop_clone/screens/events/events_details_screen.dart';
import 'package:unstop_clone/screens/events/event_dashboard.dart';

class EventsHosted extends StatefulWidget {
  const EventsHosted({super.key});

  @override
  State createState() => _EventsHostedState();
}

class _EventsHostedState extends State<EventsHosted> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        margin: EdgeInsets.all(20),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(child: Text('No user data found'));
            }

            // Get the user document data
            Map<String, dynamic>? userData =
                snapshot.data!.data() as Map<String, dynamic>?;

            // Check if hostedEvents exists and is not empty
            if (userData == null ||
                !userData.containsKey('hostedEvents') ||
                userData['hostedEvents'] == null) {
              return Center(child: Text('No events created yet'));
            }

            // Handle hostedEvents as a map instead of a list
            Map<String, dynamic> eventsMap = {};

            // Convert to map if it's not already a map
            if (userData['hostedEvents'] is Map) {
              eventsMap = Map<String, dynamic>.from(userData['hostedEvents']);
            } else if (userData['hostedEvents'] is List) {
              // If it's actually a list, convert to original code
              List<dynamic> eventsList = userData['hostedEvents'];

              if (eventsList.isEmpty) {
                return Center(child: Text('No events created yet'));
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: eventsList.length,
                itemBuilder: (context, index) {
                  final event = eventsList[index];
                  return buildEventCard(event);
                },
              );
            } else {
              return Center(child: Text('Invalid events data format'));
            }

            // If no events in the map
            if (eventsMap.isEmpty) {
              return Center(child: Text('No events created yet'));
            }

            // Display the events from map in a ListView
            List<String> eventIds = eventsMap.keys.toList();

            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: eventIds.length,
              itemBuilder: (context, index) {
                String eventId = eventIds[index];
                dynamic event = eventsMap[eventId];

                // Handle if event is a reference instead of direct data
                if (event is String) {
                  // If the value is a string (possibly a reference or ID),
                  // we need to fetch the actual event data
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('events')
                        .doc(event)
                        .get(),
                    builder: (context, eventSnapshot) {
                      if (eventSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Card(
                          margin: EdgeInsets.only(bottom: 15),
                          child: SizedBox(
                            height: 200,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        );
                      }

                      if (!eventSnapshot.hasData ||
                          !eventSnapshot.data!.exists) {
                        return Card(
                          margin: EdgeInsets.only(bottom: 15),
                          child: SizedBox(
                            height: 200,
                            child: Center(child: Text('Event not found')),
                          ),
                        );
                      }

                      Map<String, dynamic> eventData =
                          eventSnapshot.data!.data() as Map<String, dynamic>;

                      return buildEventCard(eventData);
                    },
                  );
                } else if (event is Map<String, dynamic>) {
                  // If it's already a map with the event data
                  return buildEventCard(event);
                } else {
                  // Unknown format
                  return Card(
                    margin: EdgeInsets.only(bottom: 15),
                    child: SizedBox(
                      height: 200,
                      child: Center(child: Text('Invalid event format')),
                    ),
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }

  // Helper method to build event card
  Widget buildEventCard(dynamic eventId) {
    print(eventId); // For debugging

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            margin: EdgeInsets.only(bottom: 15),
            child: SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            margin: EdgeInsets.only(bottom: 15),
            child: SizedBox(
              height: 200,
              child: Center(child: Text('Error loading event')),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Card(
            margin: EdgeInsets.only(bottom: 15),
            child: SizedBox(
              height: 200,
              child: Center(child: Text('Event not found')),
            ),
          );
        }

        // Get event data
        Map<String, dynamic> event =
            snapshot.data!.data() as Map<String, dynamic>;

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventDashBoard(eventId: eventId),
              ),
            );
          },
          child: Card(
            margin: EdgeInsets.only(bottom: 15),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event image
                event['eventImage'] != null &&
                        event['eventImage'].toString().isNotEmpty
                    ? Image.network(
                        event['eventImage'],
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 150,
                            color: Colors.grey[300],
                            child: Center(
                              child: Icon(Icons.image_not_supported, size: 50),
                            ),
                          );
                        },
                      )
                    : Container(
                        height: 150,
                        color: Colors.grey[300],
                        width: double.infinity,
                        child: Center(
                          child: Icon(Icons.image, size: 50),
                        ),
                      ),

                // Event name
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    event['eventName']?.toString() ?? 'Unnamed Event',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(7.0),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        "Date: ${event['eventDate'] ?? 'Unknown'}",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),

                // const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.all(7.0),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        "Time: ${event['eventTime'] ?? 'Unknown'}",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),

                // const SizedBox(height: 10),

                // Location
                Padding(
                  padding: const EdgeInsets.all(7.0),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          event['eventLocation'] ?? 'Location not specified',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
