import 'package:flutter/material.dart';
import 'card_mini.dart';

class GameGrid extends StatelessWidget {
  final List<dynamic> cards;
  final int myPlayerId;
  final int turn;
  final bool isTallLayout;
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
    required this.isTallLayout,
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
    final crossAxisCount = isTallLayout ? 4 : 13;
    const mainAxisSpacing = 2.0;
    const crossAxisSpacing = 2.0;
    const childAspectRatio = 0.75;

    return LayoutBuilder(builder: (context, constraints) {
      final baseWidth = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : MediaQuery.of(context).size.width;
      final safeWidth = baseWidth > 0 ? baseWidth : 1.0;
      final rows = (cards.length / crossAxisCount).ceil();
      final cardWidth =
          (safeWidth - (crossAxisCount - 1) * crossAxisSpacing) /
              crossAxisCount;
      final cardHeight = cardWidth / childAspectRatio;
      final gridHeight = rows * cardHeight + (rows - 1) * mainAxisSpacing;

      return SizedBox(
        height: gridHeight,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: mainAxisSpacing,
            crossAxisSpacing: crossAxisSpacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: cards.length,
          itemBuilder: (context, visualIndex) {
            final actualIndex = isTallLayout
                ? ((visualIndex % 4) * 13 + (visualIndex ~/ 4))
                : visualIndex;

            Map displayCard = Map.from(cards[actualIndex]);
            List<dynamic> permViewers = displayCard['permViewers'] ?? [];
            bool isPermanentlyRevealedToMe = permViewers.contains(myPlayerId);

            Color? hColor;

            // 優先順位に基づいたハイライト色
            if (selectedForExchange.contains(actualIndex)) {
              hColor = Colors.orangeAccent;
            } else if (actualIndex == firstSelectedIndex) {
              hColor = Colors.redAccent;
            } else if (tempRevealedIndices.contains(actualIndex)) {
              hColor = Colors.pinkAccent;
            } else if (highlightedIndices.contains(actualIndex)) {
              hColor = Colors.yellowAccent;
            } else if (activeEffect == 'nine') {
              hColor = _getNineZoneColor(actualIndex);
            } else if (isPermanentlyRevealedToMe) {
              hColor = Colors.orange;
            }

            // 一時透視 or 永久透視なら表にする
            if (tempRevealedIndices.contains(actualIndex) ||
                isPermanentlyRevealedToMe) {
              displayCard['isFaceUp'] = true;
            }

            return GestureDetector(
              onTap: () => onTap(actualIndex),
              child: CardMini(
                card: displayCard,
                isMyTurn: turn == myPlayerId,
                pColor: turn == myPlayerId ? Colors.blue : Colors.red,
                highlightColor: hColor,
              ),
            );
          },
        ),
      );
    });
  }
}
