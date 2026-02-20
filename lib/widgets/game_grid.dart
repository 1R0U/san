import 'package:flutter/material.dart';
import 'card_mini.dart';

class GameGrid extends StatelessWidget {
  final List<dynamic> cards;
  final int myPlayerId;
  final int turn;
  final int firstSelectedIndex;
  final List<int> highlightedIndices;
  final List<int> tempRevealedIndices;
  final List<int> selectedForExchange;
  final String? activeEffect;
  final Function(int) onTap;

  const GameGrid({
    super.key,
    required this.cards,
    required this.myPlayerId,
    required this.turn,
    required this.firstSelectedIndex,
    required this.highlightedIndices,
    required this.tempRevealedIndices,
    required this.selectedForExchange,
    this.activeEffect,
    required this.onTap,
  });

  Color? _getNineZoneColor(int index) {
    int crossAxisCount = 13;
    int r = index ~/ crossAxisCount;
    int c = index % crossAxisCount;
    if (r < 2 && c < 6) return Colors.cyanAccent.withOpacity(0.5);
    if (r < 2 && c >= 6) return Colors.orangeAccent.withOpacity(0.5);
    if (r >= 2 && c < 6) return Colors.purpleAccent.withOpacity(0.5);
    if (r >= 2 && c >= 6) return Colors.greenAccent.withOpacity(0.5);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 13,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childAspectRatio: 0.75,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        Map displayCard = Map.from(cards[index]);
        List<dynamic> permViewers = displayCard['permViewers'] ?? [];
        bool isPermanentlyRevealedToMe = permViewers.contains(myPlayerId);

        Color? hColor;

        // 優先順位に基づいたハイライト色
        if (selectedForExchange.contains(index)) {
          hColor = Colors.orangeAccent;
        } else if (index == firstSelectedIndex) {
          hColor = Colors.redAccent;
        } else if (tempRevealedIndices.contains(index)) {
          hColor = Colors.pinkAccent;
        } else if (highlightedIndices.contains(index)) {
          hColor = Colors.yellowAccent;
        } else if (activeEffect == 'nine') {
          hColor = _getNineZoneColor(index);
        } else if (isPermanentlyRevealedToMe) {
          hColor = Colors.orange;
        }

        // 一時透視 or 永久透視なら表にする
        if (tempRevealedIndices.contains(index) || isPermanentlyRevealedToMe) {
          displayCard['isFaceUp'] = true;
        }

        return GestureDetector(
          onTap: () => onTap(index),
          child: CardMini(
            card: displayCard,
            isMyTurn: turn == myPlayerId,
            pColor: turn == 1 ? Colors.blue : Colors.red,
            highlightColor: hColor,
          ),
        );
      },
    );
  }
}
