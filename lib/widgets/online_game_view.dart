import 'package:flutter/material.dart';

import '../screens/rule_screen.dart';
import 'game_grid.dart';
import 'game_header.dart';

class OnlineGameView extends StatelessWidget {
  final String roomId;
  final int myPlayerId;
  final bool isTallLayout;
  final bool isMyTurn;
  final int turnCount;
  final int maxTurns;
  final int turn;
  final Map<String, dynamic> players;
  final List<int> turnOrder;
  final List<dynamic> cards;
  final int firstSelectedIndex;
  final List<int> highlightedIndices;
  final List<int> tempRevealedIndices;
  final List<int> selectedForExchange;
  final String? activeEffect;
  final ValueChanged<int> onTap;
  final Future<void> Function() onToggleLayout;
  final Future<bool> Function() onConfirmExit;
  final Future<void> Function() onExit;

  const OnlineGameView({
    super.key,
    required this.roomId,
    required this.myPlayerId,
    required this.isTallLayout,
    required this.isMyTurn,
    required this.turnCount,
    required this.maxTurns,
    required this.turn,
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
        if (exit) await onExit();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A3D14),
        appBar: AppBar(
          toolbarHeight: 50,
          backgroundColor: isMyTurn ? Colors.blue[900] : Colors.red[900],
          title: Text(
            'TURN: $turnCount / ${maxTurns == 0 ? "∞" : "$maxTurns"}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: isTallLayout ? '横長表示に切替' : '縦長表示に切替',
              onPressed: onToggleLayout,
              icon: Icon(isTallLayout ? Icons.swap_horiz : Icons.swap_vert),
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
              myId: myPlayerId,
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
                      myPlayerId: myPlayerId,
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