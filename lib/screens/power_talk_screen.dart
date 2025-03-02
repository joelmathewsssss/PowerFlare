import 'package:flutter/material.dart';
import '../models/user.dart';

/// Screen for community discussions about solar power
class PowerTalkScreen extends StatefulWidget {
  final User user;

  const PowerTalkScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<PowerTalkScreen> createState() => _PowerTalkScreenState();
}

class _PowerTalkScreenState extends State<PowerTalkScreen> {
  // Message input controller
  final _messageController = TextEditingController();

  // List of sample messages
  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'System',
      'text': 'Welcome to Power Talk! Discuss solar power with the community.',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'isSystem': true,
    },
    {
      'sender': 'SolarExpert',
      'text':
          'Has anyone installed solar panels recently? What was your experience?',
      'timestamp': DateTime.now().subtract(const Duration(hours: 12)),
      'isSystem': false,
    },
    {
      'sender': 'GreenEnergy',
      'text': 'I installed a 5kW system last month. It\'s been great so far!',
      'timestamp': DateTime.now().subtract(const Duration(hours: 10)),
      'isSystem': false,
    },
    {
      'sender': 'SolarExpert',
      'text': 'That\'s awesome! What brand did you go with?',
      'timestamp': DateTime.now().subtract(const Duration(hours: 9)),
      'isSystem': false,
    },
    {
      'sender': 'GreenEnergy',
      'text':
          'I went with SunPower panels. They were more expensive but have a great warranty.',
      'timestamp': DateTime.now().subtract(const Duration(hours: 8)),
      'isSystem': false,
    },
  ];

  @override
  void dispose() {
    // Clean up controller
    _messageController.dispose();
    super.dispose();
  }

  /// Send a new message
  void _sendMessage() {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    setState(() {
      // Add new message to the list
      _messages.add({
        'sender': widget.user.username,
        'text': messageText,
        'timestamp': DateTime.now(),
        'isSystem': false,
      });

      // Clear the input field
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chat header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Power Talk Community',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),

        // Message list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return _buildMessageTile(message);
            },
          ),
        ),

        // Message input
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Text input field
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  minLines: 1,
                ),
              ),
              const SizedBox(width: 8.0),

              // Send button
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _sendMessage,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build a message tile
  Widget _buildMessageTile(Map<String, dynamic> message) {
    final isSystem = message['isSystem'] as bool;
    final sender = message['sender'] as String;
    final text = message['text'] as String;
    final timestamp = message['timestamp'] as DateTime;

    // Format timestamp
    final timeString = _formatTimestamp(timestamp);

    // Determine if this is the current user's message
    final isCurrentUser = sender == widget.user.username;

    // System messages have a different style
    if (isSystem) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              text,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4.0),
            Text(
              timeString,
              style: const TextStyle(
                fontSize: 12.0,
                color: Colors.black45,
              ),
            ),
          ],
        ),
      );
    }

    // Regular user messages
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar (only for other users)
          if (!isCurrentUser)
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: Text(sender[0].toUpperCase()),
            ),

          const SizedBox(width: 8.0),

          // Message content
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sender name (only for other users)
                  if (!isCurrentUser)
                    Text(
                      sender,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isCurrentUser ? Colors.white : Colors.black87,
                      ),
                    ),

                  // Message text
                  Text(
                    text,
                    style: TextStyle(
                      color: isCurrentUser ? Colors.white : Colors.black87,
                    ),
                  ),

                  // Timestamp
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        timeString,
                        style: TextStyle(
                          fontSize: 12.0,
                          color:
                              isCurrentUser ? Colors.white70 : Colors.black45,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8.0),

          // Avatar (only for current user)
          if (isCurrentUser)
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(sender[0].toUpperCase()),
            ),
        ],
      ),
    );
  }

  /// Format timestamp for display
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
