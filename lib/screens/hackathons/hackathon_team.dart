import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HackathonTeam extends StatefulWidget {
  const HackathonTeam({super.key});

  @override
  State<HackathonTeam> createState() => _HackathonTeamState();
}

class _HackathonTeamState extends State<HackathonTeam> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  Stream<QuerySnapshot>? _chatGroupsStream;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;

    // Load chat groups where current user is a member
    if (_currentUser != null) {
      _chatGroupsStream = _firestore
          .collection('chatGroups')
          .where('members', arrayContains: _currentUser!.uid)
          .snapshots();
    }
  }

  void _createNewChatRoom() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController groupNameController =
            TextEditingController();

        return AlertDialog(
          title: const Text('Create New Chat Room'),
          content: TextField(
            controller: groupNameController,
            decoration: const InputDecoration(
              labelText: 'Room Name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (groupNameController.text.isNotEmpty &&
                    _currentUser != null) {
                  // Create new chat group in Firestore
                  await _firestore.collection('chatGroups').add({
                    'name': groupNameController.text,
                    'members': [_currentUser!.uid],
                    'memberNames': [
                      {
                        'uid': _currentUser!.uid,
                        'displayName': _currentUser!.displayName ?? 'Anonymous',
                        'email': _currentUser!.email
                      }
                    ],
                    'createdAt': FieldValue.serverTimestamp(),
                    'lastMessage': null,
                    'lastMessageTime': null,
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Center(
        child: Text('Please sign in to access team chats'),
      );
    }

    return Column(
      children: [
        Expanded(
          child: _buildChatRoomsPage(),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FloatingActionButton(
              onPressed: _createNewChatRoom,
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatRoomsPage() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatGroupsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
                'No chat rooms yet. Create one by tapping the + button below.'),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final groupId = doc.id;
            final members = List<dynamic>.from(data['members'] ?? []);
            final lastMessage = data['lastMessage'];
            final lastMessageTime = data['lastMessageTime'] as Timestamp?;

            return Card(
              margin:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    (data['name'] as String? ?? 'C')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(data['name'] ?? 'Unnamed Room'),
                subtitle: Text(
                  lastMessage ?? 'No messages yet',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (lastMessageTime != null)
                      Text(
                        _formatTime(lastMessageTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '${members.length} members',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  // Navigate to the chat room
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatRoomScreen(groupId: groupId),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  String _formatTime(Timestamp timestamp) {
    final now = DateTime.now();
    final dateTime = timestamp.toDate();

    if (now.difference(dateTime).inDays == 0) {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (now.difference(dateTime).inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dateTime.weekday - 1];
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

class ChatRoomScreen extends StatefulWidget {
  final String groupId;

  const ChatRoomScreen({super.key, required this.groupId});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;

  Stream<DocumentSnapshot>? _groupStream;
  Stream<QuerySnapshot>? _messagesStream;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;

    _groupStream =
        _firestore.collection('chatGroups').doc(widget.groupId).snapshots();
    _messagesStream = _firestore
        .collection('chatGroups')
        .doc(widget.groupId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty && _currentUser != null) {
      final messageText = _messageController.text;
      _messageController.clear();

      // Fetch the user's name from Firestore
      final userDoc =
          await _firestore.collection('users').doc(_currentUser!.uid).get();
      final userName = userDoc.data()?['name'] ?? 'Anonymous';

      final messageRef = _firestore
          .collection('chatGroups')
          .doc(widget.groupId)
          .collection('messages')
          .doc();

      // Add message with the correct name from Firestore
      await messageRef.set({
        'id': messageRef.id,
        'senderId': _currentUser!.uid,
        'senderName': userName,
        'senderEmail': _currentUser!.email,
        'message': messageText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update last message in chat group
      await _firestore.collection('chatGroups').doc(widget.groupId).update({
        'lastMessage': messageText,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    }
  }

  void _addMemberToGroup() async {
    final TextEditingController newMemberController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Member to Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newMemberController,
              decoration: const InputDecoration(
                  labelText: 'Member Email',
                  border: OutlineInputBorder(),
                  hintText: 'Enter user email to add'),
            ),
            const SizedBox(height: 10),
            const Text(
              'Note: User must be registered in the app',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newMemberController.text.isNotEmpty) {
                // Get current members
                final groupDoc = await _firestore
                    .collection('chatGroups')
                    .doc(widget.groupId)
                    .get();
                final groupData = groupDoc.data() as Map<String, dynamic>;
                final currentMembers =
                    List<dynamic>.from(groupData['members'] ?? []);

                // Find user by email
                final userQuery = await _firestore
                    .collection('users')
                    .where('email', isEqualTo: newMemberController.text.trim())
                    .limit(1)
                    .get();

                if (userQuery.docs.isNotEmpty) {
                  final userData = userQuery.docs.first.data();
                  final userId = userQuery.docs.first.id;

                  // Check if user is already in the group
                  if (currentMembers.contains(userId)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('User is already in this group')),
                    );
                  } else {
                    // Add user to the group
                    await _firestore
                        .collection('chatGroups')
                        .doc(widget.groupId)
                        .update({
                      'members': FieldValue.arrayUnion([userId]),
                      'memberNames': FieldValue.arrayUnion([
                        {
                          'uid': userId,
                          'displayName': userData['displayName'] ?? 'Unknown',
                          'email': userData['email']
                        }
                      ]),
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Member added successfully')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('User not found with that email')),
                  );
                }

                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeMembers() async {
    // Get group data first
    final groupDoc =
        await _firestore.collection('chatGroups').doc(widget.groupId).get();
    final groupData = groupDoc.data() as Map<String, dynamic>;
    final memberNames =
        List<Map<String, dynamic>>.from(groupData['memberNames'] ?? []);

    // Filter out current user
    final otherMembers = memberNames
        .where((member) => member['uid'] != _currentUser!.uid)
        .toList();

    if (otherMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are the only member in this group')),
      );
      return;
    }

    // Show dialog with list of members
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Members'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: otherMembers.length,
            itemBuilder: (context, index) {
              final member = otherMembers[index];
              return ListTile(
                title: Text(member['displayName'] ?? 'Unknown'),
                subtitle: Text(member['email'] ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () async {
                    // Remove member from group
                    await _firestore
                        .collection('chatGroups')
                        .doc(widget.groupId)
                        .update({
                      'members': FieldValue.arrayRemove([member['uid']]),
                      'memberNames': FieldValue.arrayRemove([member]),
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              '${member['displayName']} removed from group')),
                    );
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _deleteGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text(
            'Are you sure you want to delete this group? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              // Delete the group
              await _firestore
                  .collection('chatGroups')
                  .doc(widget.groupId)
                  .delete();

              // Pop back to previous screen
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to chat list

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Group deleted successfully')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Only updating the relevant styling parts in your ChatRoomScreen class
// Keep all the existing functionality

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: _groupStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Text('Loading...');
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            return Text(data['name'] ?? 'Chat Room');
          },
        ),
        elevation: 2,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'add':
                  _addMemberToGroup();
                  break;
                case 'remove':
                  _removeMembers();
                  break;
                case 'delete':
                  _deleteGroup();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'add',
                child: Row(
                  children: [
                    Icon(Icons.person_add, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Add Member'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.person_remove, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Remove Members'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Group', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          // Chat background with subtle pattern
          color: Colors.grey.shade100,
          image: DecorationImage(
            image: const NetworkImage(
                'https://www.transparenttextures.com/patterns/subtle-white-feathers.png'),
            repeat: ImageRepeat.repeat,
            opacity: 0.3,
          ),
        ),
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _messagesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ));
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 64, color: Colors.blue.shade200),
                          const SizedBox(height: 16),
                          const Text(
                            'No messages yet. Start the conversation!',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final isCurrentUser =
                          data['senderId'] == _currentUser!.uid;
                      final timestamp = data['timestamp'] as Timestamp?;
                      final time = timestamp != null
                          ? '${timestamp.toDate().hour}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
                          : 'Sending...';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          mainAxisAlignment: isCurrentUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isCurrentUser)
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.purple.shade300,
                                child: Text(
                                  (data['senderName'] ?? 'U')[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (!isCurrentUser) const SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.7,
                                ),
                                decoration: BoxDecoration(
                                  color: isCurrentUser
                                      ? Colors.blue.shade500
                                      : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: isCurrentUser
                                        ? const Radius.circular(16)
                                        : const Radius.circular(4),
                                    bottomRight: isCurrentUser
                                        ? const Radius.circular(4)
                                        : const Radius.circular(16),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 10.0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['senderName'] ?? 'Unknown',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: isCurrentUser
                                            ? Colors.white.withOpacity(0.9)
                                            : Colors.blue.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      data['message'] ?? '',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: isCurrentUser
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            time,
                                            style: TextStyle(
                                              color: isCurrentUser
                                                  ? Colors.white
                                                      .withOpacity(0.7)
                                                  : Colors.grey.shade600,
                                              fontSize: 11,
                                            ),
                                          ),
                                          if (isCurrentUser) ...[
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.done_all,
                                              size: 14,
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isCurrentUser) const SizedBox(width: 8),
                            if (isCurrentUser)
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.blue.shade700,
                                child: Text(
                                  (_currentUser?.email?[0] ?? 'U')
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Message input
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24.0),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 12.0,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send),
                        color: Colors.white,
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
