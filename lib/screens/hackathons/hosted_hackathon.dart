import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unstop_clone/screens/hackathons/hackathon_dashboard.dart';

class HostedHackathon extends StatefulWidget {
  const HostedHackathon({super.key});

  @override
  State<HostedHackathon> createState() => _HostedHackathonState();
}

class _HostedHackathonState extends State<HostedHackathon> {
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

            // Check if hostedHackathons exists and is not empty
            if (userData == null ||
                !userData.containsKey('hostedHackathons') ||
                userData['hostedHackathons'] == null) {
              return Center(child: Text('No hackathons created yet'));
            }

            // Handle hostedHackathons as a map instead of a list
            Map<String, dynamic> hackathonsMap = {};

            // Convert to map if it's not already a map
            if (userData['hostedHackathons'] is Map) {
              hackathonsMap =
                  Map<String, dynamic>.from(userData['hostedHackathons']);
            } else if (userData['hostedHackathons'] is List) {
              // If it's actually a list, convert to original code
              List<dynamic> hackathonsList = userData['hostedHackathons'];

              if (hackathonsList.isEmpty) {
                return Center(child: Text('No hackathons created yet'));
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: hackathonsList.length,
                itemBuilder: (context, index) {
                  final hackathon = hackathonsList[index];
                  return buildHackathonCard(hackathon);
                },
              );
            } else {
              return Center(child: Text('Invalid hackathons data format'));
            }

            // If no hackathons in the map
            if (hackathonsMap.isEmpty) {
              return Center(child: Text('No hackathons created yet'));
            }

            // Display the hackathons from map in a ListView
            List<String> hackathonIds = hackathonsMap.keys.toList();

            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: hackathonIds.length,
              itemBuilder: (context, index) {
                String hackathonId = hackathonIds[index];
                dynamic hackathon = hackathonsMap[hackathonId];

                // Handle if hackathon is a reference instead of direct data
                if (hackathon is String) {
                  // If the value is a string (possibly a reference or ID),
                  // we need to fetch the actual hackathon data
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('hackathons')
                        .doc(hackathon)
                        .get(),
                    builder: (context, hackathonSnapshot) {
                      if (hackathonSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Card(
                          margin: EdgeInsets.only(bottom: 15),
                          child: SizedBox(
                            height: 200,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        );
                      }

                      if (!hackathonSnapshot.hasData ||
                          !hackathonSnapshot.data!.exists) {
                        return Card(
                          margin: EdgeInsets.only(bottom: 15),
                          child: SizedBox(
                            height: 200,
                            child: Center(child: Text('Hackathon not found')),
                          ),
                        );
                      }

                      Map<String, dynamic> hackathonData =
                          hackathonSnapshot.data!.data()
                              as Map<String, dynamic>;

                      return buildHackathonCard(hackathonData);
                    },
                  );
                } else if (hackathon is Map<String, dynamic>) {
                  // If it's already a map with the hackathon data
                  return buildHackathonCard(hackathon);
                } else {
                  // Unknown format
                  return Card(
                    margin: EdgeInsets.only(bottom: 15),
                    child: SizedBox(
                      height: 200,
                      child: Center(child: Text('Invalid hackathon format')),
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

  // Helper method to build hackathon card
  Widget buildHackathonCard(dynamic hackathonId) {
    print(hackathonId); // For debugging

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('hackathons')
          .doc(hackathonId)
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
              child: Center(child: Text('Error loading hackathon')),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Card(
            margin: EdgeInsets.only(bottom: 15),
            child: SizedBox(
              height: 200,
              child: Center(child: Text('Hackathon not found')),
            ),
          );
        }

        // Get hackathon data
        Map<String, dynamic> hackathon =
            snapshot.data!.data() as Map<String, dynamic>;

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    HackathonDashboard(hackathonId: hackathonId),
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
                // Hackathon image
                hackathon['hackathonImage'] != null &&
                        hackathon['hackathonImage'].toString().isNotEmpty
                    ? Image.network(
                        hackathon['hackathonImage'],
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
                          child: Icon(Icons.code, size: 50),
                        ),
                      ),

                // Hackathon name
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    hackathon['hackathonName']?.toString() ??
                        'Unnamed Hackathon',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Start date
                Padding(
                  padding: const EdgeInsets.all(7.0),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        "Start Date: ${hackathon['startDate'] ?? 'Unknown'}",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),

                // End date
                Padding(
                  padding: const EdgeInsets.all(7.0),
                  child: Row(
                    children: [
                      const Icon(Icons.event_available, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        "End Date: ${hackathon['endDate'] ?? 'Unknown'}",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),

                // Participants or Teams
                Padding(
                  padding: const EdgeInsets.all(7.0),
                  child: Row(
                    children: [
                      const Icon(Icons.people, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        "Participants: ${hackathon['registered_participants']?.length ?? 0}",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),

                // Mode (Online/Offline)
                Padding(
                  padding: const EdgeInsets.all(7.0),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        hackathon['mode'] ?? 'Mode not specified',
                        style: const TextStyle(fontSize: 16),
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
