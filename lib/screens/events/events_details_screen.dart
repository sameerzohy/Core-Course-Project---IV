import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventsDetailsScreen extends StatefulWidget {
  const EventsDetailsScreen({super.key, required this.eventId});

  final String eventId;

  @override
  State<EventsDetailsScreen> createState() => _EventsDetailsScreenState();
}

class _EventsDetailsScreenState extends State<EventsDetailsScreen> {
  final userId = FirebaseAuth.instance.currentUser!.uid;
  late Future<Map<String, dynamic>?> _eventDetailsFuture;

  @override
  void initState() {
    super.initState();
    _eventDetailsFuture = getEventDetails(widget.eventId);
  }

  Future<Map<String, dynamic>?> getEventDetails(String eventId) async {
    try {
      var response = await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .get();
      return response.data();
    } catch (e) {
      debugPrint("Error fetching event details: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        actions: [
          // Separate widget for favorite button to localize state changes
          FavoriteButton(eventId: widget.eventId),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _eventDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Event details not found."));
          }

          var eventDetails = snapshot.data!;

          // Only re-fetch event data when necessary
          return EventDetailsBody(
            eventDetails: eventDetails,
            eventId: widget.eventId,
            userId: userId,
            onEventUpdate: () {
              // Only refresh the data when we need to
              setState(() {
                _eventDetailsFuture = getEventDetails(widget.eventId);
              });
            },
          );
        },
      ),
    );
  }
}

// Separate widget for the favorite button with its own state
class FavoriteButton extends StatefulWidget {
  final String eventId;

  const FavoriteButton({super.key, required this.eventId});

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

      if (data != null && data.containsKey('favourite_events')) {
        List<dynamic> favoriteEvents = data['favourite_events'];
        isFavorite = favoriteEvents.contains(widget.eventId);
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
        'favourite_events': _isFavorite
            ? FieldValue.arrayRemove([widget.eventId])
            : FieldValue.arrayUnion([widget.eventId])
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

// Separate widget for event details body to avoid rebuilding everything
class EventDetailsBody extends StatelessWidget {
  final Map<String, dynamic> eventDetails;
  final String eventId;
  final String userId;
  final VoidCallback onEventUpdate;

  const EventDetailsBody({
    super.key,
    required this.eventDetails,
    required this.eventId,
    required this.userId,
    required this.onEventUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Banner Image
          eventDetails['eventImage'] != null
              ? Image.network(
                  eventDetails['eventImage'],
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
                // Event Name
                Text(
                  eventDetails['eventName'] ?? 'Unnamed Event',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                // Event Description
                Text(
                  eventDetails['eventDescription'] ??
                      'No description available.',
                  style: const TextStyle(fontSize: 16),
                ),

                const SizedBox(height: 20),

                // Event Date & Time
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      "Date: ${eventDetails['eventDate'] ?? 'Unknown'}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    const Icon(Icons.access_time, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      "Time: ${eventDetails['eventTime'] ?? 'Unknown'}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Location
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        eventDetails['eventLocation'] ??
                            'Location not specified',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Event Type
                Row(
                  children: [
                    const Icon(Icons.category, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      "Type: ${eventDetails['eventType'] ?? 'General'}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Event Fee
                Row(
                  children: [
                    const Icon(Icons.money, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      eventDetails['eventFee'] == 0
                          ? "Free Event"
                          : "Fee: ₹${eventDetails['eventFee']}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Payment Status
                Row(
                  children: [
                    const Icon(Icons.payment, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      "Payment: ${eventDetails['eventPayment'] ?? 'Unpaid'}",
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
                      "Name: ${eventDetails['organizerName'] ?? 'Unknown'}",
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
                      "Email: ${eventDetails['organizerEmail'] ?? 'Not available'}",
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
                      "Contact: ${eventDetails['organizerContact'] ?? 'Not available'}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Maximum Participants
                Row(
                  children: [
                    const Icon(Icons.people, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      "Max Participants: ${eventDetails['maxParticipants'] ?? 'N/A'}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),

                Row(
                  children: [
                    const Icon(Icons.people, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      "Available slots: ${eventDetails.containsKey('registered_members') ? eventDetails['maxParticipants'] - eventDetails['registered_members'].length : eventDetails['maxParticipants']}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Registration button with its own state
                RegistrationButton(
                  eventId: eventId,
                  userId: userId,
                  eventDetails: eventDetails,
                  onRegistrationChanged: onEventUpdate,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Separate widget for registration button with its own state
class RegistrationButton extends StatefulWidget {
  final String eventId;
  final String userId;
  final Map<String, dynamic> eventDetails;
  final VoidCallback onRegistrationChanged;

  const RegistrationButton({
    super.key,
    required this.eventId,
    required this.userId,
    required this.eventDetails,
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
    final eventDetails = widget.eventDetails;
    final isRegistered = eventDetails.containsKey('registered_members') &&
        eventDetails['registered_members'].contains(widget.userId);

    setState(() {
      _isRegistered = isRegistered;
    });
  }

  Future<void> _addMember() async {
    if (_isLoading) return;

    final eventDetails = widget.eventDetails;

    // Check if there are available slots
    if (eventDetails.containsKey('registered_members') &&
        (eventDetails['maxParticipants'] -
                eventDetails['registered_members'].length <=
            0)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .update({
        'registered_members': FieldValue.arrayUnion([widget.userId])
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'registered_events': FieldValue.arrayUnion([widget.eventId])
      });

      setState(() {
        _isRegistered = true;
        _isLoading = false;
      });

      widget.onRegistrationChanged();
    } catch (e) {
      debugPrint("Error adding member: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeMember() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .update({
        'registered_members': FieldValue.arrayRemove([widget.userId])
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'registered_events': FieldValue.arrayRemove([widget.eventId])
      });

      setState(() {
        _isRegistered = false;
        _isLoading = false;
      });

      widget.onRegistrationChanged();
    } catch (e) {
      debugPrint("Error removing member: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed:
            _isLoading ? null : (_isRegistered ? _removeMember : _addMember),
        style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20)),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                _isRegistered ? "Unregister" : "Register Now",
                style: const TextStyle(fontSize: 18),
              ),
      ),
    );
  }
}
