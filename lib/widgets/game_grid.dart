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

  // Wide (PC): 12 cols — one column per rank, one row per suit.
  static const _wideCols = 12;

  // Tall (phone): column count chosen so ≤12 rows appear on screen.
  int get _tallCols {
    final suitCount = cards.length ~/ 12;
    if (suitCount <= 2) return 4;  // 24 cards → 4×6
    if (suitCount <= 4) return 6;  // 48 cards → 6×8
    return 8;                       // 72 cards → 8×9,  96 cards → 8×12
  }

  // Divide board into 4 visual quadrants for the flip effect highlight.
  Color? _getNineZoneColor(int index) {
    const rankCount = 12;
    final suitCount = cards.length ~/ rankCount;
    final halfSuits = (suitCount / 2).ceil();
    final r = index ~/ rankCount;
    final c = index % rankCount;
    if (r < halfSuits && c < 6) return Colors.cyanAccent.withOpacity(0.45);
    if (r < halfSuits && c >= 6) return Colors.orangeAccent.withOpacity(0.45);
    if (r >= halfSuits && c < 6) return Colors.purpleAccent.withOpacity(0.45);
    return Colors.greenAccent.withOpacity(0.45);
  }

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = isTallLayout ? _tallCols : _wideCols;

    // Wide: more breathing room between cards; tall: tighter for small screens.
    final spacing = isTallLayout ? 2.0 : 4.0;

    // Standard playing-card proportion (2.5 : 3.5 ≈ 0.71).
    const childAspectRatio = 0.72;

    return LayoutBuilder(builder: (context, constraints) {
      final baseWidth = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : MediaQuery.of(context).size.width;
      final safeWidth = baseWidth > 0 ? baseWidth : 1.0;
      final rows = (cards.length / crossAxisCount).ceil();
      final cardWidth =
          (safeWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;
      final cardHeight = cardWidth / childAspectRatio;
      final gridHeight = rows * cardHeight + (rows - 1) * spacing;

      return SizedBox(
        height: gridHeight,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: cards.length,
          itemBuilder: (context, visualIndex) {
            // Sequential ordering in both modes — no transposition.
            // Wide: all 12 ranks fill one row (left→right), suits fill rows (top→bottom).
            // Tall: cards fill rows left→right in groups of _tallCols.
            final actualIndex = visualIndex;

            Map displayCard = Map.from(cards[actualIndex]);
            List<dynamic> permViewers = displayCard['permViewers'] ?? [];
            bool isPermanentlyRevealedToMe = permViewers.contains(myPlayerId);

            Color? hColor;
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
