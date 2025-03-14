// import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppliedHackathons extends StatefulWidget {
  const AppliedHackathons({super.key});

  @override
  State createState() => _AppliedHackathonsState();
}

class _AppliedHackathonsState extends State<AppliedHackathons> {
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

            // Check if registered_hackathons exists and is not empty
            if (userData == null ||
                !userData.containsKey('registered_hackathons') ||
                userData['registered_hackathons'] == null) {
              return Center(child: Text('Not registered to any hackathons!'));
            }

            // Handle registered_hackathons as a map instead of a list
            Map<String, dynamic> hackathonsMap = {};

            // Convert to map if it's not already a map
            if (userData['registered_hackathons'] is Map) {
              hackathonsMap =
                  Map<String, dynamic>.from(userData['registered_hackathons']);
            } else if (userData['registered_hackathons'] is List) {
              // If it's actually a list, convert to original code
              List<dynamic> hackathonsList = userData['registered_hackathons'];

              if (hackathonsList.isEmpty) {
                return Center(child: Text('No hackathons registered yet'));
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
              return Center(child: Text('Invalid hackathon data format'));
            }

            // If no hackathons in the map
            if (hackathonsMap.isEmpty) {
              return Center(child: Text('No hackathons registered yet'));
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
                builder: (context) => HackathonDetailsScreen(
                  hackathonId: hackathonId,
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

                // Dates
                Padding(
                  padding: const EdgeInsets.all(7.0),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "${hackathon['startDate'] ?? 'Unknown'} to ${hackathon['endDate'] ?? 'Unknown'}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),

                // Mode
                Padding(
                  padding: const EdgeInsets.all(7.0),
                  child: Row(
                    children: [
                      hackathon['hackathonMode'] == 'Online'
                          ? const Icon(Icons.computer, size: 20)
                          : hackathon['hackathonMode'] == 'Hybrid'
                              ? const Icon(Icons.compare_arrows, size: 20)
                              : const Icon(Icons.location_on, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        "Mode: ${hackathon['hackathonMode'] ?? 'Unknown'}",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),

                // Participation Type
                Padding(
                  padding: const EdgeInsets.all(7.0),
                  child: Row(
                    children: [
                      hackathon['participationType'] == 'Individual'
                          ? const Icon(Icons.person, size: 20)
                          : const Icon(Icons.people, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        "Participation: ${hackathon['participationType'] ?? 'Unknown'}",
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (hackathon['participationType'] == 'Team')
                        Text(
                          " (Max: ${hackathon['maxTeamSize'] ?? 'N/A'})",
                          style: const TextStyle(fontSize: 16),
                        ),
                    ],
                  ),
                ),

                // Prize
                Padding(
                  padding: const EdgeInsets.all(7.0),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Prize: ${hackathon['prize'] ?? 'Not specified'}",
                          style: const TextStyle(fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Certification
                if (hackathon['provideCertification'] == true)
                  Padding(
                    padding: const EdgeInsets.all(7.0),
                    child: Row(
                      children: [
                        const Icon(Icons.card_membership, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          "Certificate Provided",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Registration Fee if paid
                if (hackathon['isPaid'] == true)
                  Padding(
                    padding: const EdgeInsets.all(7.0),
                    child: Row(
                      children: [
                        const Icon(Icons.payment, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          "Registration Fee: ₹${hackathon['registrationFee']?.toString() ?? '0'}",
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

// Placeholder for the HackathonDetailsScreen
// You'll need to create this screen separately
class HackathonDetailsScreen extends StatelessWidget {
  final dynamic hackathonId;

  const HackathonDetailsScreen({super.key, required this.hackathonId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hackathon Details'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('hackathons')
            .doc(hackathonId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Hackathon not found'));
          }

          Map<String, dynamic> hackathon =
              snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hackathon Image
                hackathon['hackathonImage'] != null &&
                        hackathon['hackathonImage'].toString().isNotEmpty
                    ? Image.network(
                        hackathon['hackathonImage'],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 200,
                        color: Colors.grey[300],
                        width: double.infinity,
                        child: Center(
                          child: Icon(Icons.code, size: 80),
                        ),
                      ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hackathon Name
                      Text(
                        hackathon['hackathonName'] ?? 'Unnamed Hackathon',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),

                      // Description
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        hackathon['hackathonDescription'] ??
                            'No description provided',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 16),

                      // Dates and Time
                      Text(
                        'Schedule',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      ListTile(
                        leading: Icon(Icons.date_range),
                        title: Text('Start Date'),
                        subtitle:
                            Text(hackathon['startDate'] ?? 'Not specified'),
                      ),
                      ListTile(
                        leading: Icon(Icons.date_range),
                        title: Text('End Date'),
                        subtitle: Text(hackathon['endDate'] ?? 'Not specified'),
                      ),
                      ListTile(
                        leading: Icon(Icons.access_time),
                        title: Text('Start Time'),
                        subtitle:
                            Text(hackathon['startTime'] ?? 'Not specified'),
                      ),
                      ListTile(
                        leading: Icon(Icons.access_time),
                        title: Text('End Time'),
                        subtitle: Text(hackathon['endTime'] ?? 'Not specified'),
                      ),
                      SizedBox(height: 16),

                      // Venue if offline or hybrid
                      if (hackathon['hackathonMode'] != 'Online') ...[
                        Text(
                          'Venue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        ListTile(
                          leading: Icon(Icons.location_on),
                          title: Text(hackathon['venue'] ?? 'Not specified'),
                        ),
                        SizedBox(height: 16),
                      ],

                      // Participation Details
                      Text(
                        'Participation Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      ListTile(
                        leading: Icon(Icons.category),
                        title: Text('Mode'),
                        subtitle:
                            Text(hackathon['hackathonMode'] ?? 'Not specified'),
                      ),
                      ListTile(
                        leading: hackathon['participationType'] == 'Individual'
                            ? Icon(Icons.person)
                            : Icon(Icons.people),
                        title: Text('Participation Type'),
                        subtitle: Text(
                            '${hackathon['participationType'] ?? 'Not specified'}${hackathon['participationType'] == 'Team' ? ' (Max: ${hackathon['maxTeamSize'] ?? 'N/A'})' : ''}'),
                      ),
                      SizedBox(height: 16),

                      // Prize Details
                      Text(
                        'Prize Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      ListTile(
                        leading: Icon(Icons.emoji_events),
                        title: Text(hackathon['prize'] ?? 'Not specified'),
                      ),
                      if (hackathon['provideCertification'] == true)
                        ListTile(
                          leading: Icon(Icons.card_membership),
                          title: Text('Certificate will be provided'),
                        ),
                      SizedBox(height: 16),

                      // Criteria and Rules
                      Text(
                        'Criteria & Rules',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        hackathon['criteriaAndRules'] ?? 'Not specified',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 16),

                      // Organizer Information
                      Text(
                        'Organizer Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      ListTile(
                        leading: Icon(Icons.person),
                        title: Text('Organizer Name'),
                        subtitle:
                            Text(hackathon['organizerName'] ?? 'Not specified'),
                      ),
                      ListTile(
                        leading: Icon(Icons.phone),
                        title: Text('Contact'),
                        subtitle: Text(
                            hackathon['organizerContact'] ?? 'Not specified'),
                      ),
                      ListTile(
                        leading: Icon(Icons.email),
                        title: Text('Email'),
                        subtitle: Text(
                            hackathon['organizerEmail'] ?? 'Not specified'),
                      ),
                      if (hackathon['participationType'] == 'Team')
                        TeamMembersList(
                            hackathonId: hackathonId,
                            hackathonDetails: hackathon)
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class TeamMembersList extends StatelessWidget {
  final String hackathonId;
  final Map<String, dynamic> hackathonDetails;

  const TeamMembersList({
    super.key,
    required this.hackathonId,
    required this.hackathonDetails,
  });

  Future<void> _showUnregisterTeamDialog(
      BuildContext context, String teamId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Unregister Team'),
        content: const Text(
          'Are you sure you want to unregister the entire team? This will remove all team members from this hackathon.',
          style: TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Unregister',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Get all team members
        final teamSnapshot = await FirebaseFirestore.instance
            .collection('hackathon_teams')
            .doc(teamId)
            .get();

        final teamData = teamSnapshot.data() as Map<String, dynamic>;
        final memberIds = List<String>.from(teamData['members']);

        // Create a batch to perform multiple operations
        final batch = FirebaseFirestore.instance.batch();

        // Remove hackathon from registered_hackathons for all members
        for (final memberId in memberIds) {
          final userRef =
              FirebaseFirestore.instance.collection('users').doc(memberId);

          // Using map format (your code handles both formats)
          batch.update(userRef, {
            'registered_hackathons.$hackathonId': FieldValue.delete(),
          });

          // Also try array format if your app might use that
          batch.update(userRef, {
            'registered_hackathons': FieldValue.arrayRemove([hackathonId]),
          });
        }

        // Delete the team document
        batch.delete(FirebaseFirestore.instance
            .collection('hackathon_teams')
            .doc(teamId));

        // Get the current user ID
        final currentUserId = FirebaseAuth.instance.currentUser!.uid;

// Update the hackathon document to remove the user ID from registered_participants
        batch.update(
            FirebaseFirestore.instance
                .collection('hackathons')
                .doc(hackathonId),
            {
              'registered_participants': FieldValue.arrayRemove([currentUserId])
            });

        // Commit all the operations
        await batch.commit();

        // Navigate back to the previous screen after successful unregistration
        Navigator.of(context).pop();

        scaffoldMessenger.showSnackBar(
          const SnackBar(
              content:
                  Text('Team successfully unregistered from the hackathon')),
        );
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error unregistering team: $e')),
        );
      }
    }
  }

  Future<void> _showLeaveTeamDialog(
      BuildContext context, String teamId, String userId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave Team'),
        content: const Text(
          'Are you sure you want to leave this team? You will no longer be registered for this hackathon.',
          style: TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Leave Team',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Remove the user from the team
        await FirebaseFirestore.instance
            .collection('hackathon_teams')
            .doc(teamId)
            .update({
          'members': FieldValue.arrayRemove([userId]),
        });

        // Remove hackathon from user's registered_hackathons
        final userRef =
            FirebaseFirestore.instance.collection('users').doc(userId);

        // Using map format
        await userRef.update({
          'registered_hackathons.$hackathonId': FieldValue.delete(),
        });

        // Also try array format if your app might use that
        await userRef.update({
          'registered_hackathons': FieldValue.arrayRemove([hackathonId]),
        });

        // Navigate back to the previous screen after successfully leaving
        Navigator.of(context).pop();

        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Successfully left the team')),
        );
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error leaving team: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('hackathon_teams')
          .where('members', arrayContains: currentUserId)
          .where('hackathonId', isEqualTo: hackathonId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No teams found'));
        }

        final teamDoc = snapshot.data!.docs[0];
        final teamData = teamDoc.data() as Map<String, dynamic>;
        final memberIds = List<String>.from(teamData['members']);
        final teamLeaderId = teamData['teamLeaderId'] as String;
        final isTeamLeader = currentUserId == teamLeaderId;
        final teamName = teamData['teamName'] as String;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Team $teamName',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Team Members',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isTeamLeader)
                    IconButton(
                      icon: const Icon(Icons.person_add),
                      onPressed: () =>
                          _showAddMemberDialog(context, teamDoc.id, teamData),
                      tooltip: 'Add team member',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<DocumentSnapshot>>(
              future: Future.wait(
                memberIds.map((memberId) => FirebaseFirestore.instance
                    .collection('users')
                    .doc(memberId)
                    .get()),
              ),
              builder: (context, usersSnapshot) {
                if (usersSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (usersSnapshot.hasError) {
                  return const Center(child: Text('Error loading members'));
                }

                final members = usersSnapshot.data ?? [];

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final userData = member.data() as Map<String, dynamic>?;
                    final memberId = member.id;

                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(userData?['name'] ?? 'Not specified'),
                      subtitle: Text(userData?['email'] ?? 'Not specified'),
                      trailing: isTeamLeader && memberId != teamLeaderId
                          ? IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: Colors.red),
                              onPressed: () =>
                                  _removeMember(context, teamDoc.id, memberId),
                              tooltip: 'Remove member',
                            )
                          : memberId == teamLeaderId
                              ? const Chip(
                                  label: Text('Leader'),
                                  backgroundColor: Colors.blue,
                                  labelStyle: TextStyle(color: Colors.white),
                                )
                              : null,
                    );
                  },
                );
              },
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Existing team members list code...

                const SizedBox(height: 24),

                // Unregister/Leave team button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      isTeamLeader
                          ? _showUnregisterTeamDialog(context, teamDoc.id)
                          : _showLeaveTeamDialog(
                              context, teamDoc.id, currentUserId);
                    },
                    child: Text(
                      isTeamLeader ? 'Unregister Team' : 'Leave Team',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            )
          ],
        );
      },
    );
  }

  Future<void> _removeMember(
      BuildContext context, String teamId, String memberId) async {
    // Store ScaffoldMessenger context reference before the async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Member'),
        content: const Text(
            'Are you sure you want to remove this member from the team?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // First, remove the member from the team
        await FirebaseFirestore.instance
            .collection('hackathon_teams')
            .doc(teamId)
            .update({
          'members': FieldValue.arrayRemove([memberId]),
        });

        // Then, remove the hackathonId from the user's registeredHackathon array
        await FirebaseFirestore.instance
            .collection('users')
            .doc(memberId)
            .update({
          'registered_hackathons': FieldValue.arrayRemove([hackathonId]),
        });

        // Use the stored reference to show the snackbar
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Member removed successfully')),
        );
      } catch (e) {
        // Use the stored reference to show the error
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error removing member: $e')),
        );
      }
    }
  }

  Future<void> _showAddMemberDialog(BuildContext context, String teamId,
      Map<String, dynamic> teamData) async {
    await showDialog<bool>(
      context: context,
      builder: (context) => AddSingleMemberDialog(
        teamId: teamId,
        hackathonId: hackathonId,
        hackathonDetails: hackathonDetails,
      ),
    );
  }
}

class AddSingleMemberDialog extends StatefulWidget {
  final String teamId;
  final String hackathonId;
  final Map<String, dynamic> hackathonDetails;

  const AddSingleMemberDialog({
    super.key,
    required this.teamId,
    required this.hackathonId,
    required this.hackathonDetails,
  });

  @override
  _AddSingleMemberDialogState createState() => _AddSingleMemberDialogState();
}

class _AddSingleMemberDialogState extends State<AddSingleMemberDialog> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  late ScaffoldMessengerState _scaffoldMessenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Store a reference to the ScaffoldMessenger
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Team Member'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Member Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addMember,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Invite'),
        ),
      ],
    );
  }

  Future<void> _addMember() async {
    final email = _emailController.text.trim().toLowerCase();

    // Basic validation
    if (email.isEmpty) {
      _scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please enter an email address')),
      );
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get the current user's email
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || currentUser.email == null) {
        throw Exception('Current user information not available');
      }

      // Check if the email is the current user's email
      if (email == currentUser.email!.toLowerCase()) {
        throw Exception('You cannot add yourself as a team member');
      }

      // Find the user with the provided email
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userSnapshot.docs.isEmpty) {
        throw Exception('No user found with this email address');
      }

      final userId = userSnapshot.docs.first.id;

      // Check if user is already in the team
      final teamSnapshot = await FirebaseFirestore.instance
          .collection('hackathon_teams')
          .doc(widget.teamId)
          .get();

      final teamData = teamSnapshot.data();
      if (teamData == null) {
        throw Exception('Team not found');
      }

      final memberIds = List<String>.from(teamData['members']);
      if (memberIds.contains(userId)) {
        throw Exception('This user is already in your team');
      }

      // Send notification to the user
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'hackathon_notifications': FieldValue.arrayUnion([
          {
            'team_id': widget.teamId,
            'title':
                'Hackathon (${widget.hackathonDetails['hackathonName']}) Invitation',
            'hackathon_id': widget.hackathonId,
            'from': currentUser.email
          }
        ])
      });

      _scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Invitation sent successfully')),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        _scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
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
