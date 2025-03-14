import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unstop_clone/screens/hackathons/hackathon_card.dart';
import 'package:unstop_clone/screens/hackathons/hackathon_detailpage.dart';
// import 'package:unstop_clone/screens/hackathons/hackathon_details_screen.dart';

class ExploreHackathonsScreen extends StatefulWidget {
  const ExploreHackathonsScreen({super.key});

  @override
  State<ExploreHackathonsScreen> createState() =>
      _ExploreHackathonsScreenState();
}

class _ExploreHackathonsScreenState extends State<ExploreHackathonsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<String> _allHackathonIds = [];
  List<String> _filteredHackathonIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHackathons();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHackathons() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final hackathonIds = await fetchHackathonIDs();
      setState(() {
        _allHackathonIds = hackathonIds;
        _filteredHackathonIds = hackathonIds;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint("Error loading hackathons: $e");
    }
  }

  Future<List<String>> fetchHackathonIDs() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore.collection('hackathons').get();
      List<String> hackathonIDs =
          querySnapshot.docs.map((doc) => doc.id).toList();
      return hackathonIDs;
    } catch (e) {
      debugPrint("Error fetching hackathon IDs: $e");
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
          hintText: 'Search hackathons...',
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

  Widget buildHackathonList() {
    return ListView.builder(
      itemCount: _filteredHackathonIds.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final hackathonId = _filteredHackathonIds[index];
        return StreamBuilder<DocumentSnapshot>(
          stream:
              _firestore.collection('hackathons').doc(hackathonId).snapshots(),
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
                  child: Center(child: Text('Error loading hackathon')),
                ),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const SizedBox.shrink();
            }

            // Get hackathon data
            Map<String, dynamic> hackathon =
                snapshot.data!.data() as Map<String, dynamic>;

            // Check if hackathon matches the search query
            if (_searchQuery.isNotEmpty) {
              bool matches = false;

              // Search in hackathon title
              final hackathonTitle =
                  (hackathon['hackathonName'] ?? '').toString().toLowerCase();
              final hackathonDescription =
                  (hackathon['hackathonDescription'] ?? '')
                      .toString()
                      .toLowerCase();
              if (hackathonTitle.contains(_searchQuery)) {
                matches = true;
              }

              if (hackathonDescription.contains(_searchQuery)) {
                matches = true;
              }

              // Search in organizer name
              final organizerName =
                  (hackathon['organizerName'] ?? '').toString().toLowerCase();
              if (organizerName.contains(_searchQuery)) {
                matches = true;
              }

              // Search in tags if available
              final tags = hackathon['tags'] as List<dynamic>? ?? [];
              for (var tag in tags) {
                if (tag.toString().toLowerCase().contains(_searchQuery)) {
                  matches = true;
                  break;
                }
              }

              // If it doesn't match the search, return an empty container to hide it
              if (!matches) {
                return const SizedBox.shrink();
              }
            }

            return GestureDetector(
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
              child: HackathonCard(hackathonId: hackathonId),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHackathons,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  margin: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      const Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: Text(
                          'Explore Hackathons',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // Search bar
                      _buildSearchBar(),

                      // Hackathons list
                      buildHackathonList(),

                      // Show message when no search results
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _searchController,
                        builder: (context, value, _) {
                          if (value.text.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return StreamBuilder<List<bool>>(
                            stream: _checkMatchingHackathonsStream(
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
                                          'No hackathons found matching "${value.text}"',
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

                      // Show message when no hackathons available
                      if (_allHackathonIds.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Icon(Icons.code_off,
                                    size: 48, color: Colors.grey),
                                const SizedBox(height: 16),
                                const Text(
                                  'No hackathons available right now',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: _loadHackathons,
                                  child: const Text('Refresh'),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // Create a Stream-based method to check for matching hackathons
  Stream<List<bool>> _checkMatchingHackathonsStream(String query) {
    if (query.isEmpty) {
      return Stream.value([true]);
    }

    // Create a list of futures that check if each hackathon matches the query
    List<Future<bool>> matchFutures = _allHackathonIds.map((hackathonId) async {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('hackathons')
            .doc(hackathonId)
            .get();

        if (!doc.exists) return false;

        final hackathon = doc.data() as Map<String, dynamic>;

        // Check all searchable fields
        final hackathonTitle =
            (hackathon['title'] ?? '').toString().toLowerCase();
        final hackathonDescription =
            (hackathon['description'] ?? '').toString().toLowerCase();
        final organizerName =
            (hackathon['organizerName'] ?? '').toString().toLowerCase();

        // Basic field checks
        bool basicMatch = hackathonTitle.contains(query) ||
            hackathonDescription.contains(query) ||
            organizerName.contains(query);

        if (basicMatch) return true;

        // Check tags if available
        final tags = hackathon['tags'] as List<dynamic>? ?? [];
        for (var tag in tags) {
          if (tag.toString().toLowerCase().contains(query)) {
            return true;
          }
        }

        return false;
      } catch (e) {
        debugPrint("Error checking if hackathon matches: $e");
        return false;
      }
    }).toList();

    // Convert the list of futures to a Future<List<bool>>
    return Stream.fromFuture(Future.wait(matchFutures));
  }
}
