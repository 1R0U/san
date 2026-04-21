import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/game_grid.dart';
import '../widgets/game_header.dart';

class LocalGameScreen extends StatefulWidget {
  final List<String> playerNames;

  const LocalGameScreen({super.key, required this.playerNames});

  @override
  State<LocalGameScreen> createState() => _LocalGameScreenState();
}

class _LocalGameScreenState extends State<LocalGameScreen> {
  late List<dynamic> _cards;
  late Map<String, dynamic> _players;
  late List<int> _turnOrder;
  int _turn = 1;
  int _firstSelectedIndex = -1;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    final suits = ['♠', '♥', '♦', '♣'];
    final ranks = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];

    final cards = <Map<String, dynamic>>[];
    for (final s in suits) {
      for (final r in ranks) {
        cards.add({
          'rank': r,
          'suit': s,
          'isFaceUp': false,
          'isTaken': false,
          'permViewers': <int>[],
        });
      }
    }
    cards.shuffle();

    final players = <String, dynamic>{};
    for (int i = 0; i < widget.playerNames.length; i++) {
      players['${i + 1}'] = {
        'id': i + 1,
        'name': widget.playerNames[i],
        'score': 0,
        'isActive': true,
      };
    }

    final order = List<int>.generate(widget.playerNames.length, (i) => i + 1)..shuffle();

    _cards = cards;
    _players = players;
    _turnOrder = order;
    _turn = order.first;
  }

  Future<void> _onTapCard(int index) async {
    if (_isProcessing) return;
    if (_cards[index]['isFaceUp'] == true || _cards[index]['isTaken'] == true) return;

    setState(() {
      _isProcessing = true;
      _cards[index]['isFaceUp'] = true;
    });

    if (_firstSelectedIndex == -1) {
      setState(() {
        _firstSelectedIndex = index;
        _isProcessing = false;
      });
      return;
    }

    await Future.delayed(const Duration(milliseconds: 900));

    final first = _firstSelectedIndex;
    final match = _cards[first]['rank'] == _cards[index]['rank'];

    setState(() {
      if (match) {
        _cards[first]['isTaken'] = true;
        _cards[index]['isTaken'] = true;
        _players['$_turn']['score'] = (_players['$_turn']['score'] ?? 0) + 1;
      } else {
        _cards[first]['isFaceUp'] = false;
        _cards[index]['isFaceUp'] = false;
        final idx = _turnOrder.indexOf(_turn);
        _turn = _turnOrder[(idx + 1) % _turnOrder.length];
      }

      _firstSelectedIndex = -1;
      _isProcessing = false;
    });

    if (_cards.every((c) => c['isTaken'] == true) && mounted) {
      _showResult();
    }
  }

  void _showResult() {
    final sorted = _players.values.toList()
      ..sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: const Text('ゲーム終了'),
        content: SizedBox(
          width: 260,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: sorted
                .map((p) => ListTile(
                      dense: true,
                      title: Text(p['name']),
                      trailing: Text("${p['score']} pt"),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              setState(_initGame);
            },
            child: const Text('もう一回'),
          ),
          TextButton(
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
            child: const Text('ロビーへ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final exit = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('確認'),
            content: const Text('ロビーに戻りますか？'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('いいえ')),
              TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('はい')),
            ],
          ),
        );
        if (exit == true && mounted) {
          Navigator.popUntil(context, (r) => r.isFirst);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A3D14),
        appBar: AppBar(
          toolbarHeight: 50,
          backgroundColor: Colors.indigo[900],
          title: const Text('LOCAL MATCH', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: Column(
          children: [
            GameHeader(
              turn: _turn,
              players: _players,
              myId: -1,
              turnOrder: _turnOrder,
            ),
            Expanded(
              child: InteractiveViewer(
                constrained: false,
                panEnabled: true,
                boundaryMargin: const EdgeInsets.symmetric(horizontal: 120, vertical: 400),
                minScale: 0.5,
                maxScale: 3.0,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width - 16,
                    child: GameGrid(
                      cards: _cards,
                      myPlayerId: _turn,
                      turn: _turn,
                      isTallLayout: false,
                      firstSelectedIndex: _firstSelectedIndex,
                      highlightedIndices: const [],
                      tempRevealedIndices: const [],
                      selectedForExchange: const [],
                      activeEffect: null,
                      onTap: _onTapCard,
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
