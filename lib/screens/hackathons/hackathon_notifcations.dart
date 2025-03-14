import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HackathonNotifications extends StatefulWidget {
  const HackathonNotifications({super.key});

  @override
  _HackathonNotificationsState createState() => _HackathonNotificationsState();
}

class _HackathonNotificationsState extends State<HackathonNotifications> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Center(
        child: Text('You need to be logged in to view notifications'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hackathon Invitations'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('users').doc(userId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('No user data found'));
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>?;
                if (userData == null) {
                  return const Center(child: Text('User data is empty'));
                }

                final List<dynamic> notifications =
                    userData['hackathon_notifications'] ?? [];

                if (notifications.isEmpty) {
                  return const Center(
                    child: Text('No hackathon invitations yet'),
                  );
                }

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    final String teamId = notification['team_id'] ?? '';
                    final String from = notification['from'] ?? 'Unknown';
                    final String title =
                        notification['title'] ?? 'Team Invitation';

                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title.isEmpty
                                  ? 'Hackathon Team Invitation'
                                  : title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('From: $from'),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    _rejectInvitation(index);
                                  },
                                  child: const Text('Reject'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    _acceptInvitation(teamId, index);
                                  },
                                  child: const Text('Accept'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Future<void> _acceptInvitation(String teamId, int notificationIndex) async {
    if (userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get a reference to the team document
      DocumentReference teamRef =
          _firestore.collection('hackathon_teams').doc(teamId);

      // Get the team data to extract the hackathon ID
      DocumentSnapshot teamDoc = await teamRef.get();
      if (!teamDoc.exists) {
        throw Exception('Team no longer exists');
      }

      Map<String, dynamic> teamData = teamDoc.data() as Map<String, dynamic>;
      String hackathonId = teamData['hackathonId'] ?? '';

      // Add user to team members
      await teamRef.update({
        'members': FieldValue.arrayUnion([userId])
      });

      // Add hackathon to user's applied_hackathons
      await _firestore.collection('users').doc(userId).update({
        'registered_hackathons': FieldValue.arrayUnion([hackathonId])
      });

      // Remove the notification
      List<dynamic> currentNotifications =
          (await _firestore.collection('users').doc(userId).get())
                  .data()?['hackathon_notifications'] ??
              [];

      if (notificationIndex < currentNotifications.length) {
        currentNotifications.removeAt(notificationIndex);

        await _firestore
            .collection('users')
            .doc(userId)
            .update({'hackathon_notifications': currentNotifications});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully joined the team!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accepting invitation: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _rejectInvitation(int notificationIndex) async {
    if (userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current notifications
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      List<dynamic> currentNotifications =
          (userDoc.data() as Map<String, dynamic>)['hackathon_notifications'] ??
              [];

      // Remove the notification at the specified index
      if (notificationIndex < currentNotifications.length) {
        currentNotifications.removeAt(notificationIndex);

        // Update the user document
        await _firestore
            .collection('users')
            .doc(userId)
            .update({'hackathon_notifications': currentNotifications});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation rejected')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rejecting invitation: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
