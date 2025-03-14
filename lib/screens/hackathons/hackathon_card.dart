import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unstop_clone/screens/hackathons/hackathon_detailpage.dart';

class HackathonCard extends StatelessWidget {
  const HackathonCard({super.key, required this.hackathonId});
  final String hackathonId;

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
                    HackathonDetailsScreen(hackathonId: hackathonId),
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
                // Hackathon banner image
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
                            color: Colors.grey[200],
                            child: Center(
                              child: Icon(Icons.code,
                                  size: 50, color: Colors.grey[400]),
                            ),
                          );
                        },
                      )
                    : Container(
                        height: 150,
                        color: Colors.grey[200],
                        width: double.infinity,
                        child: Center(
                          child: Icon(Icons.code,
                              size: 50, color: Colors.grey[400]),
                        ),
                      ),

                // Hackathon name
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    hackathon['hackathonName']?.toString() ??
                        'Unnamed Hackathon',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Date range with icon
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${hackathon['startDate'] ?? 'TBD'} to ${hackathon['endDate'] ?? 'TBD'}",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

                // Time with icon
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        "${hackathon['startTime'] ?? 'TBD'} - ${hackathon['endTime'] ?? 'TBD'}",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),

                // Location with icon
                if (hackathon['hackathonMode'] != 'Online' &&
                    hackathon['venue'] != null)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            hackathon['venue'] ?? 'Location not specified',
                            style: const TextStyle(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Mode chip
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getModeColor(hackathon['hackathonMode']),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          hackathon['hackathonMode'] ?? 'Online',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: hackathon['participationType'] == 'Team'
                              ? Colors.purple[100]
                              : Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          hackathon['participationType'] == 'Team'
                              ? "Team (Max: ${hackathon['maxTeamSize']})"
                              : "Individual",
                          style: TextStyle(
                            fontSize: 12,
                            color: hackathon['participationType'] == 'Team'
                                ? Colors.purple[800]
                                : Colors.blue[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Prize info with icon
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events,
                          size: 16, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Prize: ${hackathon['prize'] ?? 'TBA'}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Registration fee if paid
                if (hackathon['isPaid'] == true)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.payments_outlined,
                            size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          "Registration Fee: ₹${hackathon['registrationFee']}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

// Helper function to get color based on hackathon mode
  Color _getModeColor(String? mode) {
    switch (mode) {
      case 'Online':
        return Colors.green;
      case 'Offline':
        return Colors.orange;
      case 'Hybrid':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildHackathonCard(hackathonId);
  }
}
