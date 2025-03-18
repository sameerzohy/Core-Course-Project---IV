import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Define UserModel class
class UserModel {
  final String id;
  final String email;

  UserModel({required this.id, required this.email});

  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      email: data['email'] ?? '',
    );
  }
}

// Home screen with search and conversation list
class MessagingScreen extends StatefulWidget {
  const MessagingScreen({Key? key}) : super(key: key);

  @override
  _MessagingScreenState createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailSearchController = TextEditingController();
  List<UserModel> filteredUsers = [];
  final FocusNode _focusNode = FocusNode();
  bool _isTextFieldFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isTextFieldFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _emailSearchController.dispose();
    super.dispose();
  }

  // Method to perform the search
  void _performSearch(String value) {
    if (value.isNotEmpty) {
      _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: value)
          .where('email', isLessThan: value + 'z')
          .get()
          .then((snapshot) {
        setState(() {
          filteredUsers = snapshot.docs
              .map((doc) => UserModel.fromMap(doc.id, doc.data()))
              .toList();
        });
      });
    } else {
      setState(() {
        filteredUsers = []; // Clear filtered users to show chats by default
      });
    }
  }

  // Fetch previous chats for the current user
  Stream<QuerySnapshot> _getPreviousChats() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const Stream.empty();

    return _firestore
        .collection('userchat')
        .where('participants', arrayContains: currentUser.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view messages')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10.0, 4.0, 10.0, 10.0),
            child: TextField(
              autocorrect: false,
              controller: _emailSearchController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Search for a user',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    _performSearch(_emailSearchController.text);
                  },
                ),
              ),
              onChanged: (value) {
                _performSearch(value); // Trigger search on text change
              },
            ),
          ),
          Expanded(
            child: _emailSearchController.text.isNotEmpty && _isTextFieldFocused
                ? _buildSearchResults()
                : _buildPreviousChats(currentUser.uid),
          ),
        ],
      ),
    );
  }

  // Build search results widget
  Widget _buildSearchResults() {
    return filteredUsers.isEmpty && _emailSearchController.text.isEmpty
        ? const Center(child: Text('Type to search users'))
        : filteredUsers.isEmpty && _emailSearchController.text.isNotEmpty
            ? const Center(child: Text('No users found'))
            : ListView.builder(
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        vertical: 4.0, horizontal: 8.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueGrey,
                        child: Text(
                          filteredUsers[index].email[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        filteredUsers[index].email,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('Tap to chat'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              user1: _auth.currentUser!.uid,
                              user2: filteredUsers[index].id,
                              recipientName: filteredUsers[index].email,
                            ),
                          ),
                        );
                        _emailSearchController.clear();
                        _focusNode.unfocus();
                      },
                    ),
                  );
                },
              );
  }

  // Build previous chats widget
  Widget _buildPreviousChats(String currentUserId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getPreviousChats(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading chats'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No previous chats'));
        }

        final chats = snapshot.data!.docs;

        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chatData = chats[index].data() as Map<String, dynamic>;
            final participants = chatData['participants'] as List<dynamic>;
            final otherUserId =
                participants.firstWhere((id) => id != currentUserId);

            return FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('users').doc(otherUserId).get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const ListTile(
                    title: Text('Loading...'),
                  );
                }

                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                final userEmail = userData['email'] ?? 'Unknown';

                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 4.0, horizontal: 8.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueGrey,
                      child: Text(
                        userEmail[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      userEmail,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Tap to continue chat'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            user1: currentUserId,
                            user2: otherUserId,
                            recipientName: userEmail,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ChatScreen remains unchanged
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.user1,
    required this.user2,
    required this.recipientName,
  });
  final String user1; // Sender's UID
  final String user2; // Recipient's UID
  final String recipientName;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _chatId {
    List<String> users = [widget.user1, widget.user2];
    users.sort();
    return '${users[0]}_${users[1]}';
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final messageData = {
      'senderId': currentUser.uid,
      'recipientId': widget.user2,
      'text': _messageController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('userchat')
        .doc(_chatId)
        .collection('messages')
        .add(messageData);

    // Add participants field to userchat document if it doesn't exist
    await _firestore.collection('userchat').doc(_chatId).set(
      {
        'participants': [widget.user1, widget.user2],
      },
      SetOptions(merge: true), // Merge to avoid overwriting existing data
    );

    _messageController.clear();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipientName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('userchat')
                  .doc(_chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading messages'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No messages yet'));
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message =
                        messages[index].data() as Map<String, dynamic>;
                    final isMe = message['senderId'] == _auth.currentUser?.uid;

                    return _buildMessageBubble(
                      message['text'],
                      isMe,
                      message['timestamp'] != null
                          ? (message['timestamp'] as Timestamp).toDate()
                          : DateTime.now(),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe, DateTime timestamp) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: const TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 4.0),
            Text(
              '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 12.0, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
