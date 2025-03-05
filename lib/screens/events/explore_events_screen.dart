import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unstop_clone/screens/events/events_details_screen.dart';

class ExploreEventsScreen extends StatefulWidget {
  const ExploreEventsScreen({super.key});

  @override
  State<ExploreEventsScreen> createState() => _ExploreEventsScreenState();
}

class _ExploreEventsScreenState extends State<ExploreEventsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<String> _allEventIds = [];
  List<String> _filteredEventIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final eventIds = await fetchEventIDs();
      setState(() {
        _allEventIds = eventIds;
        _filteredEventIds = eventIds;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint("Error loading events: $e");
    }
  }

  Future<List<String>> fetchEventIDs() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('events').get();
      List<String> eventIDs = querySnapshot.docs.map((doc) => doc.id).toList();
      return eventIDs;
    } catch (e) {
      debugPrint("Error fetching event IDs: $e");
      return [];
    }
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search events...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
        onChanged: _performSearch,
      ),
    );
  }

  Widget buildEventCard(String eventId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            margin: EdgeInsets.only(bottom: 15),
            child: SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Card(
            margin: EdgeInsets.only(bottom: 15),
            child: SizedBox(
              height: 200,
              child: Center(child: Text('Error loading event')),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Card(
            margin: EdgeInsets.only(bottom: 15),
            child: SizedBox(
              height: 200,
              child: Center(child: Text('Event not found')),
            ),
          );
        }

        // Get event data
        Map<String, dynamic> event =
            snapshot.data!.data() as Map<String, dynamic>;

        // Check if event matches the search query
        if (_searchQuery.isNotEmpty) {
          bool matches = false;

          // Search in event name
          final eventName = (event['eventName'] ?? '').toString().toLowerCase();
          if (eventName.contains(_searchQuery)) {
            matches = true;
          }

          // Search in event location
          final eventLocation =
              (event['eventLocation'] ?? '').toString().toLowerCase();
          if (eventLocation.contains(_searchQuery)) {
            matches = true;
          }

          // Search in event type
          final eventType = (event['eventType'] ?? '').toString().toLowerCase();
          if (eventType.contains(_searchQuery)) {
            matches = true;
          }

          // Search in organizer name
          final organizerName =
              (event['organizerName'] ?? '').toString().toLowerCase();
          if (organizerName.contains(_searchQuery)) {
            matches = true;
          }

          // If it doesn't match the search, return an empty container to hide it
          if (!matches) {
            return const SizedBox.shrink();
          }
        }

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventsDetailsScreen(
                  eventId: eventId,
                ),
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 15),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event image
                event['eventImage'] != null &&
                        event['eventImage'].toString().isNotEmpty
                    ? Image.network(
                        event['eventImage'],
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 150,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.image_not_supported, size: 50),
                            ),
                          );
                        },
                      )
                    : Container(
                        height: 150,
                        color: Colors.grey[300],
                        width: double.infinity,
                        child: const Center(
                          child: Icon(Icons.image, size: 50),
                        ),
                      ),

                // Event name
                Padding(
                  padding: const EdgeInsets.all(7),
                  child: Text(
                    event['eventName']?.toString() ?? 'Unnamed Event',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(7.0),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        "Date: ${event['eventDate'] ?? 'Unknown'}",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(7.0),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        "Time: ${event['eventTime'] ?? 'Unknown'}",
                        style: const TextStyle(fontSize: 16),
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
                          event['eventLocation'] ?? 'Location not specified',
                          style: const TextStyle(fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Search bar
                    _buildSearchBar(),

                    // Events list
                    ListView.builder(
                      itemCount: _filteredEventIds.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return buildEventCard(_filteredEventIds[index]);
                      },
                    ),

                    // Show message when no search results
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _searchController,
                      builder: (context, value, _) {
                        if (value.text.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return StreamBuilder<List<bool>>(
                          stream: _checkMatchingEventsStream(
                              value.text.toLowerCase()),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final matchResults = snapshot.data ?? [];
                            final hasMatches = matchResults.contains(true);

                            if (!hasMatches) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.search_off,
                                          size: 48, color: Colors.grey),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No events found matching "${value.text}"',
                                        style: const TextStyle(
                                            fontSize: 16, color: Colors.grey),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return const SizedBox.shrink();
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Create a Stream-based method to check for matching events
  Stream<List<bool>> _checkMatchingEventsStream(String query) {
    if (query.isEmpty) {
      return Stream.value([true]);
    }

    // Create a list of futures that check if each event matches the query
    List<Future<bool>> matchFutures = _allEventIds.map((eventId) async {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('events')
            .doc(eventId)
            .get();

        if (!doc.exists) return false;

        final event = doc.data() as Map<String, dynamic>;

        // Check all searchable fields
        final eventName = (event['eventName'] ?? '').toString().toLowerCase();
        final eventLocation =
            (event['eventLocation'] ?? '').toString().toLowerCase();
        final eventType = (event['eventType'] ?? '').toString().toLowerCase();
        final organizerName =
            (event['organizerName'] ?? '').toString().toLowerCase();

        return eventName.contains(query) ||
            eventLocation.contains(query) ||
            eventType.contains(query) ||
            organizerName.contains(query);
      } catch (e) {
        debugPrint("Error checking if event matches: $e");
        return false;
      }
    }).toList();

    // Convert the list of futures to a Future<List<bool>>
    return Stream.fromFuture(Future.wait(matchFutures));
  }
}
