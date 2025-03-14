import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unstop_clone/screens/hackathons/hackathon_update_screen.dart';

class HackathonDashboard extends StatefulWidget {
  const HackathonDashboard({super.key, required this.hackathonId});

  final String hackathonId;

  @override
  State<HackathonDashboard> createState() => _HackathonDashboardState();
}

class _HackathonDashboardState extends State<HackathonDashboard> {
  void switchScreen(index) {
    setState(() {
      _currentIndex = index;
    });
  }

  int _currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    List<Widget> screens = [
      HackathonDetailsScreen(hackathonId: widget.hackathonId),
      HackathonUpdateScreen(
          hackathonId: widget.hackathonId, switchScreen: switchScreen),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text('Hackathon Dashboard'),
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

class HackathonDetailsScreen extends StatefulWidget {
  const HackathonDetailsScreen({super.key, required this.hackathonId});

  final String hackathonId;

  @override
  State<HackathonDetailsScreen> createState() => _HackathonDetailsScreenState();
}

class _HackathonDetailsScreenState extends State<HackathonDetailsScreen> {
  final userId = FirebaseAuth.instance.currentUser!.uid;

  Future<Map<String, dynamic>?> getHackathonDetails(String hackathonId) async {
    try {
      var response = await FirebaseFirestore.instance
          .collection('hackathons')
          .doc(hackathonId)
          .get();
      return response.data();
    } catch (e) {
      debugPrint("Error fetching hackathon details: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: getHackathonDetails(widget.hackathonId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text("Hackathon details not found."));
        }

        var hackathonDetails = snapshot.data!;
        String participationType =
            hackathonDetails['registrationMode'] ?? 'Both';

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hackathon Banner Image
              hackathonDetails['hackathonImage'] != null
                  ? Image.network(
                      hackathonDetails['hackathonImage'],
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
                    // Hackathon Name
                    Text(
                      hackathonDetails['hackathonName'] ?? 'Unnamed Hackathon',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 10),

                    // Hackathon Description
                    Text(
                      hackathonDetails['hackathonDescription'] ??
                          'No description available.',
                      style: const TextStyle(fontSize: 16),
                    ),

                    const SizedBox(height: 20),

                    // Hackathon Dates
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          "Start Date: ${hackathonDetails['startDate'] ?? 'Unknown'}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Icon(Icons.event_available, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          "End Date: ${hackathonDetails['endDate'] ?? 'Unknown'}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Mode
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Mode: ${hackathonDetails['mode'] ?? 'Not specified'}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Location (if offline)
                    if (hackathonDetails['mode'] == 'Offline' &&
                        hackathonDetails.containsKey('location'))
                      Row(
                        children: [
                          const Icon(Icons.place, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Location: ${hackathonDetails['location']}",
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 20),

                    // Hackathon Type
                    Row(
                      children: [
                        const Icon(Icons.category, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          "Type: ${hackathonDetails['hackathonType'] ?? 'General'}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Hackathon Fee
                    Row(
                      children: [
                        const Icon(Icons.money, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          hackathonDetails['hackathonFee'] == 0
                              ? "Free Hackathon"
                              : "Fee: ₹${hackathonDetails['hackathonFee']}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Registration Mode
                    Row(
                      children: [
                        const Icon(Icons.people, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          "Registration Mode: ${participationType}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Team Size (if applicable)
                    if (participationType == 'Team' ||
                        participationType == 'Both')
                      Row(
                        children: [
                          const Icon(Icons.group, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            "Team Size: ${hackathonDetails['minTeamSize'] ?? '1'} - ${hackathonDetails['maxTeamSize'] ?? 'Unlimited'}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),

                    const SizedBox(height: 20),

                    // Prize Information
                    if (hackathonDetails.containsKey('prizes'))
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Prizes",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            hackathonDetails['prizes'] ??
                                'No prize information available',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),

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
                          "Name: ${hackathonDetails['organizerName'] ?? 'Unknown'}",
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
                          "Email: ${hackathonDetails['organizerEmail'] ?? 'Not available'}",
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
                          "Contact: ${hackathonDetails['organizerContact'] ?? 'Not available'}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Registration Stats
                    const Divider(thickness: 1),
                    const SizedBox(height: 10),
                    const Text(
                      "Registration Statistics",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Icon(Icons.analytics, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          "Total Registrations: ${hackathonDetails.containsKey('registered_participants') ? hackathonDetails['registered_participants'].length : 0}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Registered Participants List
                    const Text(
                      "Registered Participants",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 10),

                    _buildRegisteredParticipantsList(hackathonDetails),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRegisteredParticipantsList(
      Map<String, dynamic> hackathonDetails) {
    if (!hackathonDetails.containsKey('registered_participants') ||
        hackathonDetails['registered_participants'].isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text("No participants registered yet."),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: hackathonDetails['registered_participants'].length,
      itemBuilder: (context, index) {
        String userId = hackathonDetails['registered_participants'][index];
        return FutureBuilder<Map<String, dynamic>>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get()
              .then((snapshot) => snapshot.data() as Map<String, dynamic>),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 5),
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.hasError) {
              return Text("Error: ${snapshot.error}");
            }
            if (!snapshot.hasData || snapshot.data == null) {
              return const Text("No Data Found");
            }

            // Extract user data
            Map<String, dynamic> userData = snapshot.data!;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 5),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(userData['name']?[0] ?? '?'),
                ),
                title: Text(userData['name'] ?? 'Unknown User'),
                subtitle: Text(userData['email'] ?? 'No email provided'),
              ),
            );
          },
        );
      },
    );
  }
}
