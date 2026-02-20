import 'package:flutter/material.dart';

class GameHeader extends StatelessWidget {
  final int turn;
  final Map<String, dynamic> scores;
  final bool isMyTurn;

  const GameHeader(
      {super.key,
      required this.turn,
      required this.scores,
      required this.isMyTurn});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.black26,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _scoreText(1, scores['1'], turn == 1),
          Text(isMyTurn ? "YOUR TURN" : "WAITING...",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              )),
          _scoreText(2, scores['2'], turn == 2),
        ],
      ),
    );
  }

  Widget _scoreText(int id, dynamic score, bool active) {
    return Column(
      children: [
        Text("P$id",
            style: TextStyle(
                color: active ? Colors.white : Colors.white38, fontSize: 12)),
        Text(
          "$score pt",
          style: TextStyle(
            color: active ? Colors.white : Colors.white38,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
