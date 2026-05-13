import 'package:flutter/material.dart';

import '../screens/rule_screen.dart';
import 'game_grid.dart';
import 'game_header.dart';

class LocalGameView extends StatelessWidget {
  final bool isTallLayout;
  final int turn;
  final int turnCount;
  final int maxTurns;
  final Map<String, dynamic> players;
  final List<int> turnOrder;
  final List<dynamic> cards;
  final int firstSelectedIndex;
  final List<int> highlightedIndices;
  final List<int> tempRevealedIndices;
  final List<int> selectedForExchange;
  final String? activeEffect;
  final ValueChanged<int> onTap;
  final VoidCallback onToggleLayout;
  final Future<bool> Function() onConfirmExit;
  final VoidCallback onExit;

  const LocalGameView({
    super.key,
    required this.isTallLayout,
    required this.turn,
    required this.turnCount,
    required this.maxTurns,
    required this.players,
    required this.turnOrder,
    required this.cards,
    required this.firstSelectedIndex,
    required this.highlightedIndices,
    required this.tempRevealedIndices,
    required this.selectedForExchange,
    required this.activeEffect,
    required this.onTap,
    required this.onToggleLayout,
    required this.onConfirmExit,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final exit = await onConfirmExit();
        if (exit) onExit();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A3D14),
        appBar: AppBar(
          toolbarHeight: 50,
          backgroundColor: Colors.indigo[900],
          title: Text(
            'TURN: $turnCount / ${maxTurns == 0 ? "∞" : "$maxTurns"}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'Toggle layout',
              icon: Icon(isTallLayout ? Icons.swap_horiz : Icons.swap_vert),
              onPressed: onToggleLayout,
            ),
            IconButton(
              tooltip: 'ルール説明',
              icon: const Icon(Icons.help_outline),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RuleScreen()),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            GameHeader(
              turn: turn,
              players: players,
              myId: -1,
              turnOrder: turnOrder,
            ),
            Expanded(
              child: InteractiveViewer(
                constrained: false,
                panEnabled: true,
                boundaryMargin: const EdgeInsets.symmetric(
                  horizontal: 120,
                  vertical: 400,
                ),
                minScale: 0.5,
                maxScale: 3.0,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width - 16,
                    child: GameGrid(
                      cards: cards,
                      myPlayerId: turn,
                      turn: turn,
                      isTallLayout: isTallLayout,
                      firstSelectedIndex: firstSelectedIndex,
                      highlightedIndices: highlightedIndices,
                      tempRevealedIndices: tempRevealedIndices,
                      selectedForExchange: selectedForExchange,
                      activeEffect: activeEffect,
                      onTap: onTap,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
