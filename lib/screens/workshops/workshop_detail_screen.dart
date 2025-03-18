import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkshopDetailsScreen extends StatefulWidget {
  final String workshopId;

  const WorkshopDetailsScreen({
    super.key,
    required this.workshopId,
  });

  @override
  State<WorkshopDetailsScreen> createState() => _WorkshopDetailsScreenState();
}

class _WorkshopDetailsScreenState extends State<WorkshopDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isProcessing = false;
  bool _isUserRegistered = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workshop Details'),
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection('workshops')
            .doc(widget.workshopId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Workshop not found'));
          }

          Map<String, dynamic> workshop =
              snapshot.data!.data() as Map<String, dynamic>;

          // Check if current user is already registered
          List<dynamic> participants = workshop['participants'] ?? [];
          _isUserRegistered = participants.contains(_auth.currentUser?.uid);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Workshop image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: workshop['workshopImage'] != null &&
                          workshop['workshopImage'].toString().isNotEmpty
                      ? Image.network(
                          workshop['workshopImage'],
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey[300],
                              child: const Center(
                                child:
                                    Icon(Icons.image_not_supported, size: 50),
                              ),
                            );
                          },
                        )
                      : Container(
                          height: 200,
                          color: Colors.grey[300],
                          width: double.infinity,
                          child: const Center(
                            child: Icon(Icons.school, size: 50),
                          ),
                        ),
                ),

                const SizedBox(height: 16),

                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(workshop['status'] ?? 'Upcoming'),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    workshop['status'] ?? 'Upcoming',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Workshop title
                Text(
                  workshop['workshopTitle']?.toString() ?? 'Unnamed Workshop',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                // Organizer name
                Row(
                  children: [
                    const Icon(Icons.person, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'By ${workshop['organizerName'] ?? 'Unknown Organizer'}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Info card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dates
                        _buildInfoRow(
                          Icons.calendar_today,
                          workshop['startDate'] == workshop['endDate']
                              ? "Date: ${workshop['startDate'] ?? 'Unknown'}"
                              : "From: ${workshop['startDate'] ?? 'Unknown'} To: ${workshop['endDate'] ?? 'Unknown'}",
                        ),

                        const SizedBox(height: 12),

                        // Time
                        _buildInfoRow(
                          Icons.access_time,
                          "Time: ${workshop['startTime'] ?? 'Unknown'} - ${workshop['endTime'] ?? 'Unknown'}",
                        ),

                        const SizedBox(height: 12),

                        // Mode and location
                        _buildInfoRow(
                          workshop['workshopMode'] == 'Online'
                              ? Icons.computer
                              : workshop['workshopMode'] == 'Hybrid'
                                  ? Icons.sync_alt
                                  : Icons.location_on,
                          workshop['workshopMode'] == 'Online'
                              ? "Online (${workshop['onlinePlatform'] ?? 'Platform not specified'})"
                              : workshop['workshopMode'] == 'Hybrid'
                                  ? "Hybrid: ${workshop['venue'] ?? 'Venue not specified'}"
                                  : workshop['venue'] ?? 'Venue not specified',
                        ),

                        const SizedBox(height: 12),

                        // Registration fee
                        _buildInfoRow(
                          Icons.attach_money,
                          workshop['isPaid'] == true
                              ? "Registration Fee: ₹${workshop['registrationFee'] ?? '0'}"
                              : "Registration Fee: Free",
                          textColor: workshop['isPaid'] == true
                              ? Colors.blue
                              : Colors.green,
                        ),

                        const SizedBox(height: 12),

                        // Participants
                        _buildInfoRow(
                          Icons.people,
                          "Participants: ${(workshop['participants'] as List?)?.length ?? 0}/${workshop['maxParticipants'] ?? 'Unlimited'}",
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Description section
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  workshop['workshopDescription'] ?? 'No description provided.',
                  style: const TextStyle(fontSize: 16),
                ),

                const SizedBox(height: 24),

                // Topics covered section
                const Text(
                  'Topics Covered',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  workshop['topicsCovered'] ?? 'Topics not specified.',
                  style: const TextStyle(fontSize: 16),
                ),

                const SizedBox(height: 24),

                // Registration/Unregistration button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessing ||
                            workshop['status'] == 'Completed' ||
                            workshop['status'] == 'Cancelled' ||
                            (!_isUserRegistered &&
                                (workshop['participants'] as List?)!.length >=
                                    (workshop['maxParticipants'] ??
                                        double.infinity))
                        ? null
                        : () => _isUserRegistered
                            ? _unregisterFromWorkshop(workshop)
                            : _registerForWorkshop(workshop),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: _isUserRegistered ? Colors.red : null,
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _getButtonText(workshop),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? textColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  String _getButtonText(Map<String, dynamic> workshop) {
    if (workshop['status'] == 'Completed') {
      return 'Workshop Completed';
    } else if (workshop['status'] == 'Cancelled') {
      return 'Workshop Cancelled';
    } else if (!_isUserRegistered &&
        (workshop['participants'] as List?)!.length >=
            (workshop['maxParticipants'] ?? double.infinity)) {
      return 'Registration Full';
    } else if (_isUserRegistered) {
      return 'Unregister';
    } else {
      return 'Register Now';
    }
  }

  Future<void> _registerForWorkshop(Map<String, dynamic> workshop) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final userId = _auth.currentUser!.uid;

      // Update workshop document
      await _firestore.collection('workshops').doc(widget.workshopId).update({
        'participants': FieldValue.arrayUnion([userId])
      });

      // Update user document
      await _firestore.collection('users').doc(userId).update({
        'registered_workshops': FieldValue.arrayUnion([widget.workshopId])
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful!'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _isUserRegistered = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _unregisterFromWorkshop(Map<String, dynamic> workshop) async {
    // Show confirmation dialog
    final shouldUnregister = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Unregistration'),
        content: const Text(
            'Are you sure you want to unregister from this workshop?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Unregister'),
          ),
        ],
      ),
    );

    if (shouldUnregister != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final userId = _auth.currentUser!.uid;

      // Update workshop document
      await _firestore.collection('workshops').doc(widget.workshopId).update({
        'participants': FieldValue.arrayRemove([userId])
      });

      // Update user document
      await _firestore.collection('users').doc(userId).update({
        'registered_workshops': FieldValue.arrayRemove([widget.workshopId])
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully unregistered from workshop'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _isUserRegistered = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to unregister: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return Colors.blue;
      case 'ongoing':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
