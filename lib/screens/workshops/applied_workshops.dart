import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unstop_clone/screens/workshops/workshop_detail_screen.dart';

class AppliedWorkshops extends StatefulWidget {
  const AppliedWorkshops({super.key});

  @override
  State createState() => _AppliedWorkshopsState();
}

class _AppliedWorkshopsState extends State<AppliedWorkshops> {
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

            // Check if registeredWorkshops exists and is not empty
            if (userData == null ||
                !userData.containsKey('registered_workshops') ||
                userData['registered_workshops'] == null) {
              return Center(child: Text('Not Registered to any Workshops!'));
            }

            // Handle registeredWorkshops as a map or list
            Map<String, dynamic> workshopsMap = {};

            // Convert to map if it's not already a map
            if (userData['registered_workshops'] is Map) {
              workshopsMap =
                  Map<String, dynamic>.from(userData['registered_workshops']);
            } else if (userData['registered_workshops'] is List) {
              // If it's a list, handle it appropriately
              List<dynamic> workshopsList = userData['registered_workshops'];

              if (workshopsList.isEmpty) {
                return Center(child: Text('No Workshops Registered yet'));
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: workshopsList.length,
                itemBuilder: (context, index) {
                  final workshop = workshopsList[index];
                  return buildWorkshopCard(workshop);
                },
              );
            } else {
              return Center(child: Text('Invalid workshops data format'));
            }

            // If no workshops in the map
            if (workshopsMap.isEmpty) {
              return Center(child: Text('No workshops registered yet'));
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
                  // If the value is a string (possibly a reference or ID),
                  // we need to fetch the actual workshop data
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
                          workshopSnapshot.data!.data() as Map<String, dynamic>;

                      return buildWorkshopCard(workshopData);
                    },
                  );
                } else if (workshop is Map<String, dynamic>) {
                  // If it's already a map with the workshop data
                  return buildWorkshopCard(workshop);
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
          },
        ),
      ),
    );
  }

  // Helper method to build workshop card
  Widget buildWorkshopCard(dynamic workshopId) {
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

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WorkshopDetailsScreen(
                  workshopId: workshopId,
                ),
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

                // Workshop name
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    workshop['workshopName']?.toString() ?? 'Unnamed Workshop',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Date
                Padding(
                  padding: const EdgeInsets.all(7.0),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        "Date: ${workshop['workshopDate'] ?? 'Unknown'}",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),

                // Time
                Padding(
                  padding: const EdgeInsets.all(7.0),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        "Time: ${workshop['workshopTime'] ?? 'Unknown'}",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),

                // Instructor
                Padding(
                  padding: const EdgeInsets.all(7.0),
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Instructor: ${workshop['instructor'] ?? 'Not specified'}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),

                // Location
                Padding(
                  padding: const EdgeInsets.all(7.0),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          workshop['workshopLocation'] ??
                              'Location not specified',
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
