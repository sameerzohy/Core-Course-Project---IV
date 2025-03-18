import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unstop_clone/screens/workshops/workshop_dashboard.dart';

class WorkshopsHosted extends StatefulWidget {
  const WorkshopsHosted({super.key});

  @override
  State createState() => _WorkshopsHostedState();
}

class _WorkshopsHostedState extends State<WorkshopsHosted> {
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

            // Check if hostedWorkshops exists and is not empty
            if (userData == null ||
                !userData.containsKey('hostedWorkshops') ||
                userData['hostedWorkshops'] == null) {
              return Center(child: Text('No workshops created yet'));
            }

            // Handle hostedWorkshops as a map or list
            if (userData['hostedWorkshops'] is Map) {
              Map<String, dynamic> workshopsMap =
                  Map<String, dynamic>.from(userData['hostedWorkshops']);

              if (workshopsMap.isEmpty) {
                return Center(child: Text('No workshops created yet'));
              }

              // Display the workshops from map in a ListView
              List<String> workshopIds = workshopsMap.keys.toList();

              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: workshopIds.length,
                itemBuilder: (context, index) {
                  String workshopId = workshopIds[index];
                  dynamic workshop = workshopsMap[workshopId];

                  // Handle if workshop is a reference instead of direct data
                  if (workshop is String) {
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('workshops')
                          .doc(workshop)
                          .get(),
                      builder: (context, workshopSnapshot) {
                        if (workshopSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Card(
                            margin: EdgeInsets.only(bottom: 15),
                            child: SizedBox(
                              height: 200,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          );
                        }

                        if (!workshopSnapshot.hasData ||
                            !workshopSnapshot.data!.exists) {
                          return Card(
                            margin: EdgeInsets.only(bottom: 15),
                            child: SizedBox(
                              height: 200,
                              child: Center(child: Text('Workshop not found')),
                            ),
                          );
                        }

                        Map<String, dynamic> workshopData =
                            workshopSnapshot.data!.data()
                                as Map<String, dynamic>;

                        return buildWorkshopCard(workshop, workshopData);
                      },
                    );
                  } else if (workshop is Map<String, dynamic>) {
                    // If it's already a map with the workshop data
                    return buildWorkshopCard(workshopId, workshop);
                  } else {
                    // Unknown format
                    return Card(
                      margin: EdgeInsets.only(bottom: 15),
                      child: SizedBox(
                        height: 200,
                        child: Center(child: Text('Invalid workshop format')),
                      ),
                    );
                  }
                },
              );
            } else if (userData['hostedWorkshops'] is List) {
              // If it's a list, handle it accordingly
              List<dynamic> workshopsList = userData['hostedWorkshops'];

              if (workshopsList.isEmpty) {
                return Center(child: Text('No workshops created yet'));
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: workshopsList.length,
                itemBuilder: (context, index) {
                  final workshopId = workshopsList[index];
                  return buildWorkshopCard(workshopId, null);
                },
              );
            } else {
              return Center(child: Text('Invalid workshops data format'));
            }
          },
        ),
      ),
    );
  }

  // Helper method to build workshop card
  Widget buildWorkshopCard(
      dynamic workshopId, Map<String, dynamic>? workshopData) {
    // If workshopData is null, we need to fetch it
    if (workshopData == null) {
      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('workshops')
            .doc(workshopId)
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
                child: Center(child: Text('Error loading workshop')),
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Card(
              margin: EdgeInsets.only(bottom: 15),
              child: SizedBox(
                height: 200,
                child: Center(child: Text('Workshop not found')),
              ),
            );
          }

          // Get workshop data
          Map<String, dynamic> workshop =
              snapshot.data!.data() as Map<String, dynamic>;

          return buildWorkshopCardContent(workshopId, workshop);
        },
      );
    } else {
      // If we already have the data, build the card directly
      return buildWorkshopCardContent(workshopId, workshopData);
    }
  }

  // Helper method to build card content from workshop data
  Widget buildWorkshopCardContent(
      dynamic workshopId, Map<String, dynamic> workshop) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkshopDashBoard(workshopId: workshopId),
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
            // Workshop image
            workshop['workshopImage'] != null &&
                    workshop['workshopImage'].toString().isNotEmpty
                ? Image.network(
                    workshop['workshopImage'],
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

            // Workshop title
            Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                workshop['workshopTitle']?.toString() ?? 'Unnamed Workshop',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Date information
            Padding(
              padding: const EdgeInsets.all(7.0),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Date: ${workshop['startDate'] ?? 'Unknown'} - ${workshop['endDate'] ?? 'Unknown'}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),

            // Time information
            Padding(
              padding: const EdgeInsets.all(7.0),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    "Time: ${workshop['startTime'] ?? 'Unknown'} - ${workshop['endTime'] ?? 'Unknown'}",
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),

            // Workshop mode and location
            Padding(
              padding: const EdgeInsets.all(7.0),
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _getLocationText(workshop),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),

            // Participants info
            Padding(
              padding: const EdgeInsets.all(7.0),
              child: Row(
                children: [
                  const Icon(Icons.people, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    "Participants: ${(workshop['participants'] as List?)?.length ?? 0}/${workshop['maxParticipants'] ?? 'Unlimited'}",
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),

            // Status badge
            Padding(
              padding: const EdgeInsets.all(7.0),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(workshop['status']),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      workshop['status'] ?? 'Upcoming',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (workshop['isPaid'] == true)
                    Container(
                      margin: EdgeInsets.only(left: 8),
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "₹${workshop['registrationFee']}",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get location text based on workshop mode
  String _getLocationText(Map<String, dynamic> workshop) {
    String mode = workshop['workshopMode'] ?? 'Online';

    if (mode == 'Online') {
      return "Online (${workshop['onlinePlatform'] ?? 'Platform not specified'})";
    } else if (mode == 'Offline') {
      return workshop['venue'] ?? 'Venue not specified';
    } else if (mode == 'Hybrid') {
      return "Hybrid: ${workshop['venue'] ?? 'Venue not specified'} & ${workshop['onlinePlatform'] ?? 'Platform not specified'}";
    } else {
      return "Location not specified";
    }
  }

  // Helper method to get color based on status
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Upcoming':
        return Colors.blue;
      case 'Ongoing':
        return Colors.green;
      case 'Completed':
        return Colors.purple;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
