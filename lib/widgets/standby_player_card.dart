import 'package:flutter/material.dart';

class StandbyPlayerCard extends StatelessWidget {
  final String label;
  final bool isReady;
  final bool isJoined;
  final bool isMe;

  const StandbyPlayerCard({
    super.key,
    required this.label,
    required this.isReady,
    required this.isJoined,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.account_circle,
          size: 60,
          color: isMe
              ? Colors.blueAccent
              : (isJoined ? Colors.white : Colors.white24),
        ),
        Text(isMe ? "$label (あなた)" : label,
            style: TextStyle(
                color: isMe ? Colors.blueAccent : Colors.white,
                fontWeight: isMe ? FontWeight.bold : FontWeight.normal)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isReady ? Colors.orange : Colors.black26,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            isReady ? "READY" : (isJoined ? "WAITING" : "EMPTY"),
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
