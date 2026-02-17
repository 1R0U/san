import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/card_mini.dart';
import '../widgets/card_effects_widgets.dart';

class OnlineGameScreen extends StatefulWidget {
  final String roomId;
  final int myPlayerId;
  const OnlineGameScreen(
      {super.key, required this.roomId, required this.myPlayerId});

  @override
  State<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen> {
  bool _isProcessing = false;

  // 表示系
  List<int> _tempRevealedIndices = [];
  List<int> _highlightIndices = [];

  // ★ 交換モード用
  bool _isExchangeMode = false;
  int _exchangeRequiredCount = 0;
  List<int> _selectedForExchange = [];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final List<dynamic> cards = data['cards'];
        final Map scores = data['scores'];
        final int turn = data['currentTurn'];
        final bool isMyTurn = (turn == widget.myPlayerId);
        final int currentTurnCount = data['turnCount'] ?? 1;

        if (data['winner'] != 0) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _showResult(data['winner'], scores));
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0A3D14),
          appBar: AppBar(
            toolbarHeight: 50,
            title: Text(
                _isExchangeMode
                    ? "あと ${_exchangeRequiredCount - _selectedForExchange.length} 枚選んでください"
                    : "Room: ${widget.roomId} | Turn: $currentTurnCount",
                style: TextStyle(
                    fontSize: 14,
                    color:
                        _isExchangeMode ? Colors.orangeAccent : Colors.white)),
            backgroundColor: turn == 1 ? Colors.blue[900] : Colors.red[900],
          ),
          body: Column(
            children: [
              _buildHeader(isMyTurn, turn, scores),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 13,
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 2,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: cards.length,
                    itemBuilder: (context, index) {
                      bool revealMid = _tempRevealedIndices.contains(index);
                      bool highlight7 = _highlightIndices.contains(index);
                      bool isExchangeSelected =
                          _selectedForExchange.contains(index);

                      return GestureDetector(
                        onTap: () => _handleTap(index, data),
                        child: CardMini(
                          card: {
                            ...cards[index],
                            'isFaceUp': cards[index]['isFaceUp'] || revealMid
                          },
                          isMyTurn: isMyTurn,
                          pColor: turn == 1 ? Colors.blue : Colors.red,
                          highlightColor: isExchangeSelected
                              ? Colors.greenAccent
                              : (highlight7 ? Colors.yellowAccent : null),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _startReveal(List<int> indices, bool showContent) {
    setState(() {
      if (showContent)
        _tempRevealedIndices = indices;
      else
        _highlightIndices = indices;
    });
    Timer(const Duration(seconds: 3), () {
      if (mounted)
        setState(() {
          _tempRevealedIndices = [];
          _highlightIndices = [];
        });
    });
  }

  // ★ 交換モード開始
  void _enterExchangeMode(int count) {
    setState(() {
      _isExchangeMode = true;
      _exchangeRequiredCount = count;
      _selectedForExchange = [];
    });
  }

  Future<void> _handleTap(int index, Map<String, dynamic> data) async {
    if (_isProcessing || data['currentTurn'] != widget.myPlayerId) return;
    List<dynamic> currentCards = List.from(data['cards']);
    if (currentCards[index]['isTaken'] || data['winner'] != 0) return;

    // --- ★ 交換モード時のタップ ---
    if (_isExchangeMode) {
      if (_selectedForExchange.contains(index)) return;
      setState(() {
        _selectedForExchange.add(index);
      });

      if (_selectedForExchange.length >= _exchangeRequiredCount) {
        setState(() => _isProcessing = true);
        final docRef =
            FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);
        currentCards =
            GameEffects.swapSpecificCards(currentCards, _selectedForExchange);
        await docRef.update({'cards': currentCards});
        setState(() {
          _isExchangeMode = false;
          _selectedForExchange = [];
          _isProcessing = false;
        });
      }
      return;
    }

    // --- 通常のタップ（めくる） ---
    if (currentCards[index]['isFaceUp']) return;
    setState(() => _isProcessing = true);
    final docRef =
        FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);
    int firstIdx = data['firstSelectedIndex'];

    if (firstIdx == -1) {
      currentCards[index]['isFaceUp'] = true;
      await docRef.update({'cards': currentCards, 'firstSelectedIndex': index});
      setState(() => _isProcessing = false);
    } else {
      currentCards[index]['isFaceUp'] = true;
      await docRef.update({'cards': currentCards});

      bool isMatch =
          currentCards[firstIdx]['rank'] == currentCards[index]['rank'];
      int currentTurnCount = (data['turnCount'] ?? 0) + 1;
      Map<String, dynamic> newScores = Map.from(data['scores']);

      if (isMatch) {
        await Future.delayed(const Duration(milliseconds: 600));
        currentCards[firstIdx]['isTaken'] = true;
        currentCards[index]['isTaken'] = true;
        newScores[widget.myPlayerId.toString()] =
            (newScores[widget.myPlayerId.toString()] ?? 0) +
                _getCardPoint(currentCards[index]['rank']);

        String rank = currentCards[index]['rank'];
        if (rank == 'Q')
          currentCards = GameEffects.applyQueenEffect(currentCards, 13);
        else if (rank == 'J')
          currentCards = GameEffects.applyJackEffect(currentCards, 13);
        else if (rank == '10')
          currentCards = GameEffects.applyTenEffect(currentCards);
        else if (rank == '9')
          currentCards = GameEffects.applyNineEffect(currentCards, 13);
        else if (rank == '8')
          _enterExchangeMode(2); // 8: 2枚交換
        else if (rank == '7') {
          final res = GameEffects.applySevenEffect(currentCards);
          currentCards = res['cards'];
          _startReveal(List<int>.from(res['targetIndices']), false);
        } else if (rank == '6')
          _startReveal(
              GameEffects.getRandomRevealIndices(currentCards, 3), true);
        else if (rank == '3')
          _enterExchangeMode(6); // 3: 4枚交換（2~6の間で固定）
        else if (rank == 'A')
          _startReveal(
              GameEffects.getRandomRevealIndices(currentCards, 8), true);

        bool allTaken = currentCards.every((c) => c['isTaken']);
        int winner = (allTaken || currentTurnCount >= (data['maxTurns'] ?? 30))
            ? _judgeWinner(newScores)
            : 0;

        await docRef.update({
          'cards': currentCards,
          'scores': newScores,
          'firstSelectedIndex': -1,
          'turnCount': currentTurnCount,
          'winner': winner,
        });
        setState(() => _isProcessing = false);
      } else {
        await Future.delayed(const Duration(milliseconds: 1000));
        currentCards[firstIdx]['isFaceUp'] = false;
        currentCards[index]['isFaceUp'] = false;
        int winner = (currentTurnCount >= (data['maxTurns'] ?? 30))
            ? _judgeWinner(newScores)
            : 0;
        await docRef.update({
          'cards': currentCards,
          'firstSelectedIndex': -1,
          'currentTurn': widget.myPlayerId == 1 ? 2 : 1,
          'turnCount': currentTurnCount,
          'winner': winner
        });
        setState(() => _isProcessing = false);
      }
    }
  }

  int _getCardPoint(String rank) {
    if (rank == 'A') return 1;
    if (rank == 'J') return 11;
    if (rank == 'Q') return 12;
    if (rank == 'K') return 13;
    return int.tryParse(rank) ?? 0;
  }

  int _judgeWinner(Map s) {
    int s1 = s['1'] ?? 0;
    int s2 = s['2'] ?? 0;
    return s1 > s2 ? 1 : (s2 > s1 ? 2 : 3);
  }

  Widget _buildHeader(bool myTurn, int turn, Map s) {
    return Container(
        color: Colors.black26,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _scoreText("P1", s['1'], turn == 1),
          Text(myTurn ? "YOUR TURN" : "WAITING...",
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
          _scoreText("P2", s['2'], turn == 2),
        ]));
  }

  Widget _scoreText(String label, int score, bool active) => Column(children: [
        Text(label,
            style: TextStyle(
                color: active ? Colors.white : Colors.white38, fontSize: 10)),
        Text("$score pt",
            style: TextStyle(
                color: active ? Colors.white : Colors.white38,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ]);
  void _showResult(int w, Map s) {
    String t = w == 3 ? "DRAW" : (w == widget.myPlayerId ? "WIN!" : "LOSE...");
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
              title: Text(t),
              content: Text("P1: ${s['1']} - P2: ${s['2']}"),
              actions: [
                TextButton(
                    onPressed: () =>
                        Navigator.popUntil(context, (r) => r.isFirst),
                    child: const Text("ロビー"))
              ],
            ));
  }
}
