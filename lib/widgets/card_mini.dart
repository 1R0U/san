import 'package:flutter/material.dart';

class CardMini extends StatelessWidget {
  final Map card;
  final bool isMyTurn;
  final Color pColor;
  final bool isHighlighted; // ★追加：ハイライトするかどうか

  const CardMini({
    super.key,
    required this.card,
    required this.isMyTurn,
    required this.pColor,
    this.isHighlighted = false, // デフォルトはfalse
  });

  @override
  Widget build(BuildContext context) {
    if (card['isTaken']) return const SizedBox.shrink();

    bool isFaceUp = card['isFaceUp'];
    String suit = card['suit'];
    String rank = card['rank'];
    bool isRed = (suit == '♥' || suit == '♦');

    return AnimatedContainer(
      // ContainerをAnimatedContainerに変更（色が滑らかに変わる）
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isFaceUp ? Colors.white : pColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(4),
        border: isHighlighted
            ? Border.all(color: Colors.yellowAccent, width: 4) // ★ハイライト時は太い黄色枠
            : (isFaceUp ? Border.all(color: Colors.grey, width: 1) : null),
        boxShadow: isHighlighted
            ? [
                const BoxShadow(color: Colors.yellow, blurRadius: 10)
              ] // ★光るエフェクト
            : [],
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
