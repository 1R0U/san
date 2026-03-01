import 'package:flutter/material.dart';

class StandbyPlayerCard extends StatelessWidget {
  final String label;
  final bool isReady;
  final bool isJoined;
  final bool isMe;
  final VoidCallback? onEdit; // ★名前変更ダイアログを出すためのコールバック

  const StandbyPlayerCard({
    super.key,
    required this.label,
    required this.isReady,
    required this.isJoined,
    required this.isMe,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Icon(Icons.account_circle,
                size: 60,
                color: isMe
                    ? Colors.blueAccent
                    : (isJoined ? Colors.white : Colors.white24)),
            if (isMe)
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Colors.blueAccent, shape: BoxShape.circle),
                    child:
                        const Icon(Icons.edit, size: 12, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: isMe ? onEdit : null, // 名前部分をタップしても変更できるように
          child: SizedBox(
            width: 100,
            child: Text(
              isMe ? "$label (あなた)" : label,
              style: TextStyle(
                color: isMe ? Colors.blueAccent : Colors.white,
                fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
                decoration: isMe
                    ? TextDecoration.underline
                    : TextDecoration.none, // 自分の名前はリンク風に
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
              color: isReady ? Colors.orange : Colors.black26,
              borderRadius: BorderRadius.circular(10)),
          child: Text(isReady ? "READY" : (isJoined ? "WAITING" : "EMPTY"),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
