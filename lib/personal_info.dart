import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late Stream<DocumentSnapshot> _userStream;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // Get current user ID
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      // Create a stream to listen to the user document
      _userStream = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots();
    }
  }

  void _signOut() async {
    try {
      FirebaseAuth.instance.signOut();
      // Navigate to login screen or handle sign out
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return "${dateTime.day} ${_getMonthName(dateTime.month)} ${dateTime.year}";
  }

  String _getMonthName(int month) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return monthNames[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          // Sign Out Button
          TextButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout, color: Colors.white),
            label:
                const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User profile not found'));
          }

          // Get user data from the document
          final userData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          userData['name'] != null
                              ? userData['name']
                                  .toString()
                                  .substring(0, 1)
                                  .toUpperCase()
                              : '?',
                          style:
                              const TextStyle(fontSize: 40, color: Colors.blue),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        userData['name'] ?? 'User',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        userData['email'] ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Personal Information
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),

                _buildInfoItem('Roll No', userData['rollNo'] ?? 'N/A'),
                _buildInfoItem('Department', userData['department'] ?? 'N/A'),
                _buildInfoItem('College', userData['collegeName'] ?? 'N/A'),
                _buildInfoItem(
                    'Date of Birth',
                    userData['dateOfBirth'] != null
                        ? (userData['dateOfBirth'] is Timestamp
                            ? _formatTimestamp(
                                userData['dateOfBirth'] as Timestamp)
                            : userData['dateOfBirth'].toString())
                        : 'N/A'),
                const SizedBox(height: 24),

                // Participation
                const Text(
                  'Participation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                const SizedBox(height: 20),

                _buildListItem(
                    'Hosted Events', userData['hostedEvents'] ?? [], 'events'),
                const SizedBox(height: 20),

                _buildListItem('Hosted Hackathons',
                    userData['hostedHackathons'] ?? [], 'hackathons'),
                const SizedBox(height: 20),

                _buildListItem('Hosted Workshops',
                    userData['hostedWorkshops'] ?? [], 'workshops'),
                const SizedBox(height: 20),

                _buildListItem('Registered Events',
                    userData['registered_events'] ?? [], 'evens'),
                const SizedBox(height: 20),

                _buildListItem('Registered Hackathons',
                    userData['registered_hackathons'] ?? [], 'hackathons'),
                const SizedBox(height: 20),

                _buildListItem('Registered Workshops',
                    userData['registered_workshops'] ?? [], 'workshops'),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(String label, List<dynamic> items, String mode) {
    String collectionName = '';
    String titleField = '';
    // Determine collection name and title field based on mode
    if (mode == 'hackathons') {
      collectionName = 'hackathons';
      titleField = 'hackathonName';
    } else if (mode == 'workshops') {
      collectionName = 'workshops';
      titleField = 'workshopTitle';
    } else {
      collectionName = 'events';
      titleField = 'eventName';
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0), // Small bottom padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          items.isEmpty
              ? const Text('None',
                  style: TextStyle(fontStyle: FontStyle.italic))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, index) {
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection(collectionName)
                          .doc(items[index])
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Text('• Loading...',
                              style: TextStyle(fontSize: 14));
                        }
                        if (snapshot.hasError) {
                          return Text('• Error loading item',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.red));
                        }
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return Text('• Item not found',
                              style: TextStyle(
                                  fontSize: 14, fontStyle: FontStyle.italic));
                        }
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        final title = data[titleField] ?? 'Untitled';
                        return Padding(
                          padding: const EdgeInsets.only(
                              bottom: 1.0), // Tiny spacing between items
                          child: Text(
                            '• $title',
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      },
                    );
                  },
                ),
        ],
      ),
    );
  }
}
