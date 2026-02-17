import 'package:flutter/material.dart';

class CardMini extends StatelessWidget {
  final Map card;
  final bool isMyTurn;
  final Color pColor;

  const CardMini({
    super.key,
    required this.card,
    required this.isMyTurn,
    required this.pColor,
  });

  @override
  Widget build(BuildContext context) {
    if (card['isTaken']) return const SizedBox.shrink();

    bool isFaceUp = card['isFaceUp'];
    String suit = card['suit'];
    String rank = card['rank'];
    bool isRed = (suit == '♥' || suit == '♦');

    return Container(
      decoration: BoxDecoration(
        color: isFaceUp ? Colors.white : pColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(2),
        border: isFaceUp ? Border.all(color: Colors.grey, width: 1) : null,
      ),
      child: Center(
        child: isFaceUp
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(suit,
                      style: TextStyle(
                          fontSize: 10,
                          color: isRed ? Colors.red : Colors.black)),
                  Text(rank,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isRed ? Colors.red : Colors.black,
                          height: 1)),
                ],
              )
            : const Icon(Icons.help_outline, size: 12, color: Colors.white24),
      ),
    );
  }
}
