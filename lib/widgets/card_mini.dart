import 'package:flutter/material.dart';

class CardMini extends StatelessWidget {
  final Map card;
  final bool isMyTurn;
  final Color pColor;
  final Color? highlightColor;

  const CardMini({
    super.key,
    required this.card,
    required this.isMyTurn,
    required this.pColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    if (card['isTaken'] ?? false) return const SizedBox.shrink();

    final isFaceUp = card['isFaceUp'] ?? false;
    final suit = card['suit'] ?? '';
    final rank = card['rank'] ?? '';
    final isRed = (suit == '♥' || suit == '♦' || suit == '♡' || suit == '♢');
    final textColor = isRed ? Colors.red[700]! : Colors.grey[900]!;

    return LayoutBuilder(builder: (_, constraints) {
      // Scale text to card size so it always fits.
      final cardW = constraints.maxWidth;
      final suitSize = (cardW * 0.28).clamp(7.0, 14.0);
      final rankSize = (cardW * 0.34).clamp(9.0, 17.0);

      return Container(
        decoration: BoxDecoration(
          color: isFaceUp ? Colors.white : pColor.withOpacity(0.85),
          borderRadius: BorderRadius.circular(3),
          border: highlightColor != null
              ? Border.all(color: highlightColor!, width: 2.5)
              : (isFaceUp
                  ? Border.all(color: Colors.grey.shade400, width: 0.8)
                  : null),
          boxShadow: highlightColor != null
              ? [
                  BoxShadow(
                      color: highlightColor!.withOpacity(0.55),
                      blurRadius: 6,
                      spreadRadius: 2)
                ]
              : null,
        ),
        child: Center(
          child: isFaceUp
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(suit,
                        style: TextStyle(
                            fontSize: suitSize,
                            color: textColor,
                            height: 1.1)),
                    Text(rank,
                        style: TextStyle(
                            fontSize: rankSize,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            height: 1.0)),
                  ],
                )
              : Icon(Icons.help_outline,
                  size: (cardW * 0.45).clamp(8.0, 20.0),
                  color: highlightColor != null
                      ? Colors.white70
                      : Colors.white38),
        ),
      );
    });
  }
}
