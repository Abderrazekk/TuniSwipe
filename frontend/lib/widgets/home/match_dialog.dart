import 'package:flutter/material.dart';
import '../../models/user.dart';

class MatchDialog extends StatelessWidget {
  final User user;
  final String matchMessage;
  final VoidCallback onKeepSwiping;
  final VoidCallback onSendMessage;

  const MatchDialog({
    super.key,
    required this.user,
    required this.matchMessage,
    required this.onKeepSwiping,
    required this.onSendMessage,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        "It's a Match! 🎉",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.pink,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: user.photo.isNotEmpty
                ? NetworkImage('http://10.0.2.2:5000/uploads/${user.photo}')
                : const AssetImage('assets/default_avatar.png')
                    as ImageProvider,
          ),
          const SizedBox(height: 16),
          Text(
            matchMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onKeepSwiping,
          child: const Text('Keep Swiping'),
        ),
        ElevatedButton(
          onPressed: onSendMessage,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink,
            foregroundColor: Colors.white,
          ),
          child: const Text('Send Message'),
        ),
      ],
    );
  }
}