import 'package:flutter/material.dart';

class GameHeader extends StatelessWidget {
  final int turn;
  final Map<String, dynamic> scores;
  final bool isMyTurn;
  final String p1Name;
  final String p2Name;

  const GameHeader({
    super.key,
    required this.turn,
    required this.scores,
    required this.isMyTurn,
    required this.p1Name,
    required this.p2Name,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.black26,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _scoreText(p1Name, scores['1'], turn == 1),
          Text(isMyTurn ? "YOUR TURN" : "WAITING...",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          _scoreText(p2Name, scores['2'], turn == 2),
        ],
      ),
    );
  }

  Widget _scoreText(String name, dynamic score, bool active) {
    return Column(
      children: [
        SizedBox(
          width: 80,
          child: Text(name,
              style: TextStyle(
                  color: active ? Colors.white : Colors.white38, fontSize: 11),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center),
        ),
        Text("$score pt",
            style: TextStyle(
                color: active ? Colors.white : Colors.white38,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}
