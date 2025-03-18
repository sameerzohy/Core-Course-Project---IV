import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:unstop_clone/screens/workshops/workshop_detail_screen.dart';

class ExploreWorkshopsScreen extends StatefulWidget {
  const ExploreWorkshopsScreen({super.key});

  @override
  State<ExploreWorkshopsScreen> createState() => _ExploreWorkshopsScreenState();
}

class _ExploreWorkshopsScreenState extends State<ExploreWorkshopsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<String> _allWorkshopIds = [];
  List<String> _filteredWorkshopIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkshops();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkshops() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final workshopIds = await fetchWorkshopIDs();
      setState(() {
        _allWorkshopIds = workshopIds;
        _filteredWorkshopIds = workshopIds;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint("Error loading workshops: $e");
    }
  }

  Future<List<String>> fetchWorkshopIDs() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore.collection('workshops').get();
      List<String> workshopIDs =
          querySnapshot.docs.map((doc) => doc.id).toList();
      return workshopIDs;
    } catch (e) {
      debugPrint("Error fetching workshop IDs: $e");
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
          hintText: 'Search workshops...',
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

  Widget buildWorkshopCard(String workshopId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('workshops')
          .doc(workshopId)
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
              child: Center(child: Text('Error loading workshop')),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Card(
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

        // Check if workshop matches the search query
        if (_searchQuery.isNotEmpty) {
          bool matches = false;

          // Search in workshop title
          final workshopTitle =
              (workshop['workshopTitle'] ?? '').toString().toLowerCase();
          if (workshopTitle.contains(_searchQuery)) {
            matches = true;
          }

          // Search in venue/location
          final venue = (workshop['venue'] ?? '').toString().toLowerCase();
          if (venue.contains(_searchQuery)) {
            matches = true;
          }

          // Search in workshop mode
          final workshopMode =
              (workshop['workshopMode'] ?? '').toString().toLowerCase();
          if (workshopMode.contains(_searchQuery)) {
            matches = true;
          }

          // Search in organizer name
          final organizerName =
              (workshop['organizerName'] ?? '').toString().toLowerCase();
          if (organizerName.contains(_searchQuery)) {
            matches = true;
          }

          // Search in topics covered
          final topicsCovered =
              (workshop['topicsCovered'] ?? '').toString().toLowerCase();
          if (topicsCovered.contains(_searchQuery)) {
            matches = true;
          }

          // If it doesn't match the search, return an empty container to hide it
          if (!matches) {
            return const SizedBox.shrink();
          }
        }

        // Format registration fee
        String feeText = 'Free';
        if (workshop['isPaid'] == true) {
          final fee = workshop['registrationFee'] ?? 0;
          feeText = '₹${fee.toString()}';
        }

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    WorkshopDetailsScreen(workshopId: workshopId),
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
                          child: Icon(Icons.school, size: 50),
                        ),
                      ),

                // Workshop title
                Padding(
                  padding: const EdgeInsets.all(7),
                  child: Text(
                    workshop['workshopTitle']?.toString() ?? 'Unnamed Workshop',
                    style: const TextStyle(
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
                          workshop['startDate'] == workshop['endDate']
                              ? "Date: ${workshop['startDate'] ?? 'Unknown'}"
                              : "From: ${workshop['startDate'] ?? 'Unknown'} To: ${workshop['endDate'] ?? 'Unknown'}",
                          style: const TextStyle(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                        "Time: ${workshop['startTime'] ?? 'Unknown'} - ${workshop['endTime'] ?? 'Unknown'}",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),

                // Mode and Location
                Padding(
                  padding: const EdgeInsets.all(7.0),
                  child: Row(
                    children: [
                      Icon(
                        workshop['workshopMode'] == 'Online'
                            ? Icons.computer
                            : workshop['workshopMode'] == 'Hybrid'
                                ? Icons.sync_alt
                                : Icons.location_on,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          workshop['workshopMode'] == 'Online'
                              ? "Online (${workshop['onlinePlatform'] ?? 'Platform not specified'})"
                              : workshop['workshopMode'] == 'Hybrid'
                                  ? "Hybrid: ${workshop['venue'] ?? 'Venue not specified'}"
                                  : workshop['venue'] ?? 'Venue not specified',
                          style: const TextStyle(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Fee and participants
                Padding(
                  padding: const EdgeInsets.all(7.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Fee
                      Row(
                        children: [
                          const Icon(Icons.attach_money, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            feeText,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: workshop['isPaid'] == true
                                  ? Colors.blue
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      // Participants count
                      Row(
                        children: [
                          const Icon(Icons.people, size: 20),
                          const SizedBox(width: 5),
                          Text(
                            "${(workshop['participants'] as List?)?.length ?? 0}/${workshop['maxParticipants'] ?? 'Unlimited'}",
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status indicator
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  color: _getStatusColor(workshop['status'] ?? 'Upcoming'),
                  child: Center(
                    child: Text(
                      workshop['status'] ?? 'Upcoming',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Text(
                      'Explore Workshops',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Search bar
                    _buildSearchBar(),

                    // Workshops list
                    ListView.builder(
                      itemCount: _filteredWorkshopIds.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return buildWorkshopCard(_filteredWorkshopIds[index]);
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
                          stream: _checkMatchingWorkshopsStream(
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
                                        'No workshops found matching "${value.text}"',
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

  // Create a Stream-based method to check for matching workshops
// Create a Stream-based method to check for matching workshops
  Stream<List<bool>> _checkMatchingWorkshopsStream(String query) {
    if (query.isEmpty) {
      return Stream.value([true]);
    }

    // Create a list of futures that check if each workshop matches the query
    List<Future<bool>> matchFutures = _allWorkshopIds.map((workshopId) async {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('workshops')
            .doc(workshopId)
            .get();

        if (!doc.exists) return false;

        final workshop = doc.data() as Map<String, dynamic>;

        // Check various fields for matches
        final workshopTitle =
            (workshop['workshopTitle'] ?? '').toString().toLowerCase();
        final venue = (workshop['venue'] ?? '').toString().toLowerCase();
        final workshopMode =
            (workshop['workshopMode'] ?? '').toString().toLowerCase();
        final organizerName =
            (workshop['organizerName'] ?? '').toString().toLowerCase();
        final topicsCovered =
            (workshop['topicsCovered'] ?? '').toString().toLowerCase();

        return workshopTitle.contains(query) ||
            venue.contains(query) ||
            workshopMode.contains(query) ||
            organizerName.contains(query) ||
            topicsCovered.contains(query);
      } catch (e) {
        debugPrint('Error checking workshop match: $e');
        return false;
      }
    }).toList();

    // Convert list of futures to a stream that emits a list of results
    return Stream.fromFuture(Future.wait(matchFutures));
  }
}
