import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unstop_clone/message.dart';
// Import the file where CustomImage is defined.
import 'package:unstop_clone/screens/events/events_details_screen.dart';
import 'package:unstop_clone/personal_info.dart';
import 'package:unstop_clone/screens/hackathons/applied_hackathons.dart';
import 'package:unstop_clone/screens/workshops/workshop_detail_screen.dart';

class CustomImage extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final BoxFit fit;

  const CustomImage({
    Key? key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if the URL is a valid network URL.
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return _fallbackWidget();
        },
      );
    }
    // If it is a file URL, load using Image.file
    else if (imageUrl.startsWith('file://')) {
      final filePath = imageUrl.replaceFirst('file://', '');
      return Image.file(
        File(filePath),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return _fallbackWidget();
        },
      );
    }
    // Fallback to a network image if the URL isn't valid
    else {
      return Image.network(
        'https://www.teameacc.org/wp-content/uploads/sites/8/2022/04/events.jpg',
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return _fallbackWidget();
        },
      );
    }
  }

  Widget _fallbackWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Icon(Icons.image_not_supported, size: 40),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (cxt) => MessagingScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => UserProfileScreen(),
                ),
              );
            },
          ),
        ],
        title: const Text('Unlock', style: TextStyle(fontSize: 30)),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Unlock new Challenges',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight:
                        Theme.of(context).textTheme.bodyLarge!.fontWeight,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: Text(
                  'Events:',
                  textAlign: TextAlign.start,
                  style: TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 240,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('events')
                      .orderBy('createdAt', descending: true)
                      .limit(3)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No events found'));
                    }
                    final events = snapshot.data!.docs;
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final eventData =
                            events[index].data() as Map<String, dynamic>;
                        final eventName =
                            eventData['eventName'] ?? 'Untitled Event';

                        String eventImage = eventData['eventImage'] ?? '';
                        final fallbackImage =
                            'https://www.teameacc.org/wp-content/uploads/sites/8/2022/04/events.jpg';

                        if (eventImage.trim().isEmpty ||
                            !(eventImage.startsWith('http://') ||
                                eventImage.startsWith('https://') ||
                                eventImage.startsWith('file://'))) {
                          eventImage = fallbackImage;
                        }

                        final eventId = events[index].id;

                        return InkWell(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (cxt) =>
                                    EventsDetailsScreen(eventId: eventId)));
                          },
                          child: Card(
                            margin: const EdgeInsets.all(10),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(15),
                                  ),
                                  child: CustomImage(
                                    imageUrl: eventImage,
                                    width: 240,
                                    height: 160,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: SizedBox(
                                    width: 220,
                                    child: Text(
                                      eventName,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: Text(
                  'Hackathons:',
                  textAlign: TextAlign.start,
                  style: TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 240,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('hackathons')
                      .orderBy('createdAt', descending: true)
                      .limit(3)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No Hackathons found'));
                    }
                    final hackathons = snapshot.data!.docs;
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: hackathons.length,
                      itemBuilder: (context, index) {
                        final hackathonData =
                            hackathons[index].data() as Map<String, dynamic>;
                        final hackathonName = hackathonData['hackathonName'] ??
                            'Untitled Hackathon';
                        String hackathonImage =
                            hackathonData['hackathonImage'] ?? '';
                        final fallbackImage =
                            'https://www.teameacc.org/wp-content/uploads/sites/8/2022/04/events.jpg';

                        // Validate image URL
                        if (hackathonImage.trim().isEmpty ||
                            !(hackathonImage.startsWith('http://') ||
                                hackathonImage.startsWith('https://') ||
                                hackathonImage.startsWith('file://'))) {
                          hackathonImage = fallbackImage;
                        }

                        final hackathonId = hackathons[index].id;

                        return InkWell(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (cxt) => HackathonDetailsScreen(
                                    hackathonId: hackathonId)));
                          },
                          child: Card(
                            margin: const EdgeInsets.all(10),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(15),
                                  ),
                                  child: CustomImage(
                                    imageUrl: hackathonImage,
                                    width: 240,
                                    height: 160,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: SizedBox(
                                    width: 220,
                                    child: Text(
                                      hackathonName,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: Text(
                  'Workshops:',
                  textAlign: TextAlign.start,
                  style: TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 240,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('workshops')
                      .orderBy('createdAt', descending: true)
                      .limit(3)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No Workshops found'));
                    }
                    final workshops = snapshot.data!.docs;
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: workshops.length,
                      itemBuilder: (context, index) {
                        final workshopData =
                            workshops[index].data() as Map<String, dynamic>;
                        final workshopName = workshopData['workshopTitle'] ??
                            'Untitled Workshop';
                        String workshopImage =
                            workshopData['workshopImage'] ?? '';
                        final fallbackImage =
                            'https://www.teameacc.org/wp-content/uploads/sites/8/2022/04/events.jpg';

                        // Validate image URL
                        if (workshopImage.trim().isEmpty ||
                            !(workshopImage.startsWith('http://') ||
                                workshopImage.startsWith('https://') ||
                                workshopImage.startsWith('file://'))) {
                          workshopImage = fallbackImage;
                        }

                        final workshopId = workshops[index].id;

                        return InkWell(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (cxt) => WorkshopDetailsScreen(
                                    workshopId: workshopId)));
                          },
                          child: Card(
                            margin: const EdgeInsets.all(10),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(15),
                                  ),
                                  child: CustomImage(
                                    imageUrl: workshopImage,
                                    width: 240,
                                    height: 160,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: SizedBox(
                                    width: 220,
                                    child: Text(
                                      workshopName,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              )

              // Repeat similar changes for Hackathons and Workshops sections...
            ],
          ),
        ),
      ),
    );
  }
}
