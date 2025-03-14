import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HackathonDetailsScreen extends StatefulWidget {
  const HackathonDetailsScreen({super.key, required this.hackathonId});

  final String hackathonId;

  @override
  State<HackathonDetailsScreen> createState() => _HackathonDetailsScreenState();
}

class _HackathonDetailsScreenState extends State<HackathonDetailsScreen> {
  final userId = FirebaseAuth.instance.currentUser!.uid;
  late Future<Map<String, dynamic>?> _hackathonDetailsFuture;

  @override
  void initState() {
    super.initState();
    _hackathonDetailsFuture = getHackathonDetails(widget.hackathonId);
  }

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hackathon Details'),
        actions: [
          // Favorite button widget for hackathons
          FavoriteButton(hackathonId: widget.hackathonId),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _hackathonDetailsFuture,
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

          return HackathonDetailsBody(
            hackathonDetails: hackathonDetails,
            hackathonId: widget.hackathonId,
            userId: userId,
            onHackathonUpdate: () {
              setState(() {
                _hackathonDetailsFuture =
                    getHackathonDetails(widget.hackathonId);
              });
            },
          );
        },
      ),
    );
  }
}

class FavoriteButton extends StatefulWidget {
  final String hackathonId;

  const FavoriteButton({super.key, required this.hackathonId});

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool _isFavorite = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    try {
      var userId = FirebaseAuth.instance.currentUser!.uid;
      var response = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      var data = response.data();
      bool isFavorite = false;

      if (data != null && data.containsKey('favourite_hackathons')) {
        List<dynamic> favoriteHackathons = data['favourite_hackathons'];
        isFavorite = favoriteHackathons.contains(widget.hackathonId);
      }

      setState(() {
        _isFavorite = isFavorite;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading favorite status: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    setState(() {
      _isLoading = true;
    });

    try {
      var userId = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'favourite_hackathons': _isFavorite
            ? FieldValue.arrayRemove([widget.hackathonId])
            : FieldValue.arrayUnion([widget.hackathonId])
      });

      setState(() {
        _isFavorite = !_isFavorite;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error toggling favorite: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(
              Icons.favorite,
              color: _isFavorite ? Colors.red : Colors.white,
            ),
      onPressed: _isLoading ? null : _toggleFavorite,
    );
  }
}

class HackathonDetailsBody extends StatelessWidget {
  final Map<String, dynamic> hackathonDetails;
  final String hackathonId;
  final String userId;
  final VoidCallback onHackathonUpdate;

  const HackathonDetailsBody({
    super.key,
    required this.hackathonDetails,
    required this.hackathonId,
    required this.userId,
    required this.onHackathonUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hackathon Banner Image
          hackathonDetails['hackathonImage'] != null &&
                  hackathonDetails['hackathonImage'].isNotEmpty
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

                // Hackathon Mode
                Row(
                  children: [
                    const Icon(Icons.work, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      "Mode: ${hackathonDetails['hackathonMode'] ?? 'Not specified'}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Participation Type
                Row(
                  children: [
                    const Icon(Icons.people, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      "Participation: ${hackathonDetails['participationType'] ?? 'Not specified'}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),

                // Team Size (only if Team participation)
                if (hackathonDetails['participationType'] == 'Team')
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.group, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          "Max Team Size: ${hackathonDetails['maxTeamSize'] ?? '4'}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Date & Time Section
                const Text(
                  'Date & Time',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // Start Date
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      "Start Date: ${hackathonDetails['startDate'] ?? 'Not specified'}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // End Date
                Row(
                  children: [
                    const Icon(Icons.event, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      "End Date: ${hackathonDetails['endDate'] ?? 'Not specified'}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Start Time
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      "Start Time: ${hackathonDetails['startTime'] ?? 'Not specified'}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // End Time
                Row(
                  children: [
                    const Icon(Icons.timer, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      "End Time: ${hackathonDetails['endTime'] ?? 'Not specified'}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Venue
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Venue: ${hackathonDetails['venue'] ?? 'Not specified'}",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Prize Section
                Row(
                  children: [
                    const Icon(Icons.emoji_events, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Prize: ${hackathonDetails['prize'] ?? 'Not specified'}",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Certification
                Row(
                  children: [
                    const Icon(Icons.card_membership, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      "Certification: ${hackathonDetails['provideCertification'] == true ? 'Yes' : 'No'}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Criteria & Rules
                const Text(
                  'Criteria & Rules',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    hackathonDetails['criteriaAndRules'] ??
                        'No criteria specified.',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),

                const SizedBox(height: 20),

                // Registration Fee
                Row(
                  children: [
                    const Icon(Icons.attach_money, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      hackathonDetails['isPaid'] == true
                          ? "Registration Fee: ₹${hackathonDetails['registrationFee']}"
                          : "Registration Fee: Free",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Organizer Details
                const Divider(thickness: 1),
                const SizedBox(height: 10),
                const Text(
                  "Organizer Information",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

                const SizedBox(height: 30),

                // Registration/Team Joining Button
                RegistrationButton(
                  hackathonId: hackathonId,
                  userId: userId,
                  hackathonDetails: hackathonDetails,
                  onRegistrationChanged: onHackathonUpdate,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RegistrationButton extends StatefulWidget {
  final String hackathonId;
  final String userId;
  final Map<String, dynamic> hackathonDetails;
  final VoidCallback onRegistrationChanged;

  const RegistrationButton({
    super.key,
    required this.hackathonId,
    required this.userId,
    required this.hackathonDetails,
    required this.onRegistrationChanged,
  });

  @override
  State<RegistrationButton> createState() => _RegistrationButtonState();
}

class _RegistrationButtonState extends State<RegistrationButton> {
  bool _isRegistered = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkRegistrationStatus();
  }

  void _checkRegistrationStatus() {
    final hackathonDetails = widget.hackathonDetails;
    final isRegistered =
        hackathonDetails.containsKey('registered_participants') &&
            hackathonDetails['registered_participants'].contains(widget.userId);

    setState(() {
      _isRegistered = isRegistered;
    });
  }

  Future<void> _register() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Determine if this is individual or team registration
      bool isTeam = widget.hackathonDetails['participationType'] == 'Team';

      if (isTeam) {
        // For team hackathons, we might want to collect team info
        bool? shouldProceed = await _showTeamRegistrationDialog();
        if (shouldProceed != true) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Update the hackathon document
      await FirebaseFirestore.instance
          .collection('hackathons')
          .doc(widget.hackathonId)
          .update({
        'registered_participants': FieldValue.arrayUnion([widget.userId])
      });

      // Update the user's document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'registered_hackathons': FieldValue.arrayUnion([widget.hackathonId])
      });

      setState(() {
        _isRegistered = true;
        _isLoading = false;
      });

      widget.onRegistrationChanged();

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isTeam
                ? "Your team has been registered for the hackathon!"
                : "You have been registered for the hackathon!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error registering for hackathon: $e");
      setState(() {
        _isLoading = false;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool?> _showTeamRegistrationDialog() async {
    final teamNameController = TextEditingController();
    final int maxTeamSize = widget.hackathonDetails['maxTeamSize'] ?? 4;
    List<TextEditingController> memberControllers = [];

    // Create controllers for member inputs (max team size - 1 as the user is one member)
    for (int i = 0; i < maxTeamSize - 1; i++) {
      memberControllers.add(TextEditingController());
    }

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Team Registration'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('Please enter your team details:'),
                const SizedBox(height: 20),
                TextField(
                  controller: teamNameController,
                  decoration: const InputDecoration(
                    labelText: 'Team Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Team Members (including you):'),
                const SizedBox(height: 10),
                // First member is the current user
                TextField(
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Member 1 (You)',
                    hintText: widget.userId,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                // Dynamically add input fields for additional members
                for (int i = 0; i < memberControllers.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextField(
                      controller: memberControllers[i],
                      decoration: InputDecoration(
                        labelText: 'Member ${i + 2} (email or user ID)',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
                child: const Text('Register'),
                onPressed: () async {
                  // Validate team name
                  if (teamNameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a team name')),
                    );
                    return;
                  }

                  // Get the current user's email
                  User? currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser == null || currentUser.email == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Current user information not available')),
                    );
                    return;
                  }

                  String currentUserEmail = currentUser.email!.toLowerCase();

                  // Collect and validate member emails
                  List<String> memberEmails = [];
                  Set<String> uniqueEmails = {}; // Set to track duplicates

                  // Check each controller for email validity and uniqueness
                  for (int i = 0; i < memberControllers.length; i++) {
                    String email = memberControllers[i].text.trim();

                    if (email.isEmpty) {
                      continue; // Skip empty fields
                    }

                    // Basic email validation
                    bool isValidEmail =
                        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(email);

                    if (!isValidEmail) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Invalid email format: $email')),
                      );
                      return;
                    }

                    String normalizedEmail = email.toLowerCase();

                    // Check if the email is the same as the current user's email
                    if (normalizedEmail == currentUserEmail) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'You cannot add yourself as a team member')),
                      );
                      return;
                    }

                    // Check for duplicates
                    if (uniqueEmails.contains(normalizedEmail)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Duplicate email: $email')),
                      );
                      return;
                    }

                    // Add to tracking collections
                    uniqueEmails.add(normalizedEmail);
                    memberEmails.add(
                        normalizedEmail); // Use normalized emails consistently
                  }

                  // Create a team document in Firestore
                  try {
                    // Start with the team leader's ID
                    List<String> memberIds = [widget.userId];
                    List<String> subMembersIds = [];

                    // Only proceed with the query if we have emails to look up
                    if (memberEmails.isNotEmpty) {
                      try {
                        // Query Firestore for users matching these emails
                        QuerySnapshot userSnapshot = await FirebaseFirestore
                            .instance
                            .collection('users')
                            .where('email', whereIn: memberEmails)
                            .get();

                        // Add found user IDs to the memberIds list
                        for (var doc in userSnapshot.docs) {
                          subMembersIds.add(doc.id);
                        }

                        // Check if any emails weren't found
                        List<String> foundEmails = userSnapshot.docs
                            .map((doc) => (doc.data()
                                as Map<String, dynamic>)['email'] as String)
                            .toList();

                        List<String> missingEmails = memberEmails
                            .where((email) => !foundEmails.contains(email))
                            .toList();

                        if (missingEmails.isNotEmpty) {
                          // Show error to user instead of just logging
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Some emails are not registered: ${missingEmails.join(", ")}')),
                          );
                          return; // Don't proceed with team creation
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error finding user IDs: $e')),
                        );
                        return; // Don't proceed with team creation
                      }
                    }

                    // Now create the team with the collected member IDs
                    var teamDoc = await FirebaseFirestore.instance
                        .collection('hackathon_teams')
                        .add({
                      'hackathonId': widget.hackathonId,
                      'teamName': teamNameController.text.trim(),
                      'teamLeaderId': widget.userId,
                      'members': memberIds,
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    for (String memId in subMembersIds) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(memId)
                          .update({
                        'hackathon_notifications': FieldValue.arrayUnion([
                          {
                            'team_id': teamDoc.id,
                            'title':
                                'Hackathon (${widget.hackathonDetails['hackathonName']}) Invitation',
                            'hackathon_id': widget.hackathonId,
                            'from': FirebaseAuth.instance.currentUser?.email
                          }
                        ])
                      });
                    }

                    if (context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                  } catch (e) {
                    debugPrint("Error creating team: $e");
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error creating team: $e")),
                      );
                    }
                  }
                }),
          ],
        );
      },
    );
  }

  Future<void> _unregister() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if this was a team registration
      bool isTeam = widget.hackathonDetails['participationType'] == 'Team';

      if (isTeam) {
        // Check if user is a team leader and handle team deletion
        QuerySnapshot teamSnapshot = await FirebaseFirestore.instance
            .collection('hackathon_teams')
            .where('hackathonId', isEqualTo: widget.hackathonId)
            .where('teamLeaderId', isEqualTo: widget.userId)
            .get();

        if (teamSnapshot.docs.isNotEmpty) {
          // User is a team leader - confirm before deleting the team
          bool? confirmDelete = await _showTeamDeletionDialog();
          if (confirmDelete != true) {
            setState(() {
              _isLoading = false;
            });
            return;
          }

          // Delete the team document
          for (var doc in teamSnapshot.docs) {
            await doc.reference.delete();
          }
        }
      }

      // Update the hackathon document
      await FirebaseFirestore.instance
          .collection('hackathons')
          .doc(widget.hackathonId)
          .update({
        'registered_participants': FieldValue.arrayRemove([widget.userId])
      });

      // Update the user's document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'registered_hackathons': FieldValue.arrayRemove([widget.hackathonId])
      });

      setState(() {
        _isRegistered = false;
        _isLoading = false;
      });

      widget.onRegistrationChanged();

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isTeam
                ? "Your team has been unregistered from the hackathon."
                : "You have been unregistered from the hackathon."),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error unregistering from hackathon: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool?> _showTeamDeletionDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Unregistration'),
          content: const Text(
              'You are the team leader. Unregistering will remove your entire team from this hackathon. Do you want to continue?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Unregister Team'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isTeam = widget.hackathonDetails['participationType'] == 'Team';

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed:
            _isLoading ? null : (_isRegistered ? _unregister : _register),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          backgroundColor: _isRegistered ? Colors.red : null,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                _isRegistered
                    ? isTeam
                        ? "Unregister Team"
                        : "Unregister"
                    : isTeam
                        ? "Register Team"
                        : "Register Now",
                style: const TextStyle(fontSize: 18),
              ),
      ),
    );
  }
}
