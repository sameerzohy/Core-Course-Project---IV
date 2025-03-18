import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CommunityForumScreen extends StatefulWidget {
  const CommunityForumScreen({super.key, required this.homeIndex});
  final void Function(int index) homeIndex;

  @override
  State<CommunityForumScreen> createState() => _CommunityForumState();
}

class _CommunityForumState extends State<CommunityForumScreen> {
  final List<String> forum_types = [
    'all',
    'general',
    'workshops',
    'events',
    'hackathons',
    'news',
    'updates'
  ];
  String _selectedCategory = 'all';
  bool _isIndexCreating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Forum'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              widget.homeIndex(0);
            });
          },
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: forum_types.length,
              itemBuilder: (context, index) {
                final category = forum_types[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                          _isIndexCreating = false;
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getPostsStream(),
              builder: (context, snapshot) {
                print("Selected category: $_selectedCategory");
                print("Connection state: ${snapshot.connectionState}");

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  print("Error loading posts: ${snapshot.error}");

                  // Handle index creation error
                  if (snapshot.error
                          .toString()
                          .contains('failed-precondition') &&
                      snapshot.error.toString().contains('requires an index')) {
                    setState(() {
                      _isIndexCreating = true;
                    });

                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'This query requires a Firebase index.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              // Switch to 'all' category temporarily
                              setState(() {
                                _selectedCategory = 'all';
                                _isIndexCreating = false;
                              });
                            },
                            child: const Text('Show all posts instead'),
                          ),
                        ],
                      ),
                    );
                  }

                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child:
                        Text('No posts found in $_selectedCategory category.'),
                  );
                }

                final posts = snapshot.data!.docs;
                print(
                    "Found ${posts.length} posts in $_selectedCategory category");

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return ForumPostcard(postId: post.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (cxt) => CreatePostScreen(types: forum_types),
          ));
        },
        tooltip: 'Add Post',
        child: const Icon(Icons.add),
      ),
    );
  }

  Stream<QuerySnapshot> _getPostsStream() {
    // If we're showing all posts or we had an index error previously
    if (_selectedCategory == 'all') {
      return FirebaseFirestore.instance
          .collection('community_posts')
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else {
      // Try the approach that doesn't require a composite index first
      return FirebaseFirestore.instance
          .collection('community_posts')
          .where('type', isEqualTo: _selectedCategory)
          .snapshots();
    }
  }
}

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key, required this.types});
  final List<String> types;

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String? _selectedPostType;

  Future<String> getUserName() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();
// Safely extract the 'name' field
    final data = userDoc.data() as Map<String, dynamic>?;
    return data?['name'] as String? ?? 'User';
  }

  // Function to submit the post to Firebase
  Future<void> _submitPost() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('community_posts').add({
          'title': _titleController.text.trim(),
          'message': _messageController.text.trim(),
          'type': _selectedPostType,
          'createdAt': FieldValue.serverTimestamp(),
          'likes': [],
          'comments': [],
          'from': FirebaseAuth.instance.currentUser!.uid,
          'user_name': await getUserName(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully!')),
        );
        Navigator.pop(context); // Go back after successful submission
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create post: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Post Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  if (value.length > 100) {
                    return 'Title must be less than 100 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // Post Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedPostType,
                decoration: const InputDecoration(
                  labelText: 'Post Type',
                  border: OutlineInputBorder(),
                ),
                items: widget.types.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPostType = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a post type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // Post Message
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Post Message',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a message';
                  }
                  if (value.length < 10) {
                    return 'Message must be at least 10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),

              // Post Button
              ElevatedButton(
                onPressed: _submitPost,
                style: ElevatedButton.styleFrom(
                  minimumSize:
                      const Size(double.infinity, 50), // Full-width button
                ),
                child: const Text('Post'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ForumPostcard extends StatefulWidget {
  final String postId;

  const ForumPostcard({super.key, required this.postId});

  @override
  _ForumPostcardState createState() => _ForumPostcardState();
}

class _ForumPostcardState extends State<ForumPostcard> {
  Map<String, dynamic>? postData;
  bool isLiked = false;
  int likeCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPostData();
  }

  Future<void> _fetchPostData() async {
    try {
      final postSnapshot = await FirebaseFirestore.instance
          .collection('community_posts')
          .doc(widget.postId)
          .get();

      if (postSnapshot.exists) {
        final user = FirebaseAuth.instance.currentUser;
        final data = postSnapshot.data() as Map<String, dynamic>;
        final likes = data['likes'] as List<dynamic>? ?? [];

        setState(() {
          postData = data;
          likeCount = likes.length;
          isLiked = user != null && likes.contains(user.uid);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching post: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to like posts')),
      );
      return;
    }

    final postRef = FirebaseFirestore.instance
        .collection('community_posts')
        .doc(widget.postId);

    setState(() {
      if (isLiked) {
        likeCount--;
        isLiked = false;
      } else {
        likeCount++;
        isLiked = true;
      }
    });

    try {
      if (isLiked) {
        await postRef.update({
          'likes': FieldValue.arrayUnion([user.uid]),
        });
      } else {
        await postRef.update({
          'likes': FieldValue.arrayRemove([user.uid]),
        });
      }
    } catch (e) {
      setState(() {
        if (isLiked) {
          likeCount--;
          isLiked = false;
        } else {
          likeCount++;
          isLiked = true;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating like: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container();
    }

    if (postData == null) {
      return const Center(child: Text('Post not found'));
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(postId: widget.postId),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          postData!['user_name'] ?? 'Unknown User',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          postData!['createdAt'] != null
                              ? DateFormat.yMMMd().add_jm().format(
                                  (postData!['createdAt'] as Timestamp)
                                      .toDate())
                              : 'No date',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(postData!['type'] ?? 'General'),
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    backgroundColor: Colors.blue[100],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                postData!['title'] ?? 'Untitled',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                postData!['message'] != null &&
                        (postData!['message'] as String).length > 150
                    ? '${(postData!['message'] as String).substring(0, 150)}...'
                    : postData!['message'] ?? '',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.grey[600],
                        ),
                        iconSize: 16,
                        onPressed: _toggleLike,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$likeCount',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.comment_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(postData!['comments'] as List?)?.length ?? 0} comments',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  Map<String, dynamic>? postData;
  bool isLiked = false;
  int likeCount = 0;
  bool isLoading = true;

  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPostData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchPostData() async {
    try {
      final postSnapshot = await FirebaseFirestore.instance
          .collection('community_posts')
          .doc(widget.postId)
          .get();

      if (postSnapshot.exists) {
        final user = FirebaseAuth.instance.currentUser;
        final data = postSnapshot.data() as Map<String, dynamic>;
        final likes = data['likes'] as List<dynamic>? ?? [];

        setState(() {
          postData = data;
          likeCount = likes.length;
          isLiked = user != null && likes.contains(user.uid);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching post: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to like posts')),
      );
      return;
    }

    final postRef = FirebaseFirestore.instance
        .collection('community_posts')
        .doc(widget.postId);

    setState(() {
      if (isLiked) {
        likeCount--;
        isLiked = false;
      } else {
        likeCount++;
        isLiked = true;
      }
    });

    try {
      if (isLiked) {
        await postRef.update({
          'likes': FieldValue.arrayUnion([user.uid]),
        });
      } else {
        await postRef.update({
          'likes': FieldValue.arrayRemove([user.uid]),
        });
      }
    } catch (e) {
      setState(() {
        if (isLiked) {
          likeCount--;
          isLiked = false;
        } else {
          likeCount++;
          isLiked = true;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating like: $e')),
      );
    }
  }

  Future<String> getUserName() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();
// Safely extract the 'name' field
    final data = userDoc.data() as Map<String, dynamic>?;
    return data?['name'] as String? ?? 'User';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (postData == null) {
      return const Center(child: Text('Post not found'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              postData!['user_name'] ?? 'Unknown User',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              postData!['createdAt'] != null
                                  ? DateFormat.yMMMd().add_jm().format(
                                      (postData!['createdAt'] as Timestamp)
                                          .toDate())
                                  : 'No date',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Chip(
                        label: Text(postData!['type'] ?? 'General'),
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                        backgroundColor: Colors.blue[100],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    postData!['title'] ?? 'Untitled',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    postData!['message'] != null &&
                            (postData!['message'] as String).length > 150
                        ? '${(postData!['message'] as String).substring(0, 150)}...'
                        : postData!['message'] ?? '',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.grey[600],
                            ),
                            iconSize: 16,
                            onPressed: _toggleLike,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$likeCount',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.comment_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(postData!['comments'] as List?)?.length ?? 0} comments',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('community_posts')
                  .doc(widget.postId)
                  .snapshots(),
              builder: (context, snapshot) {
                // First check connection state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Then check for errors
                if (snapshot.hasError) {
                  print("Error: ${snapshot.error}");
                  return Text('Error: ${snapshot.error}');
                }

                // Then check if data exists
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  print("No data available");
                  return const Center(child: Text("Post not found"));
                }

                // Safely access data
                try {
                  final postData =
                      snapshot.data!.data() as Map<String, dynamic>;

                  // Check if comments field exists
                  if (!postData.containsKey('comments') ||
                      postData['comments'] == null) {
                    print("Comments field not found");
                    return const Center(child: Text("No comments yet"));
                  }

                  final comments = postData['comments'] as List<dynamic>;
                  print("Comments found: ${comments.length}");

                  if (comments.isEmpty) {
                    return const Center(child: Text("No comments yet"));
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index] as Map<String, dynamic>;
                      return ListTile(
                        title: Text(comment['text'] ?? "No text"),
                        subtitle: Text(comment['userName'] ?? "Unknown user"),
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                      );
                    },
                  );
                } catch (e) {
                  print("Error processing data: $e");
                  return Text('Error processing data: $e');
                }
              },
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: TextField(
              decoration: InputDecoration(
                  label: Text('Comment...'),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () async {
                      // _addComment(_commentController.text);
                      await FirebaseFirestore.instance
                          .collection('community_posts')
                          .doc(widget.postId)
                          .update({
                        'comments': FieldValue.arrayUnion([
                          {
                            'text': _commentController.text,
                            'timestamp': DateTime.now(),
                            'userId': FirebaseAuth.instance.currentUser!.uid,
                            'userName': await getUserName(),
                          }
                        ])
                      });

                      _commentController.clear();
                    },
                  )),
              controller: _commentController,
            ),
          )
        ],
      ),
    );
  }
}
