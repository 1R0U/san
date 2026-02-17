import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/card_mini.dart';
import '../widgets/card_effects_widgets.dart'; // Q, J, 10, 9の特殊効果

class OnlineGameScreen extends StatefulWidget {
  final String roomId;
  final int myPlayerId;

  const OnlineGameScreen({
    super.key,
    required this.roomId,
    required this.myPlayerId,
  });

  @override
  State<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final List<dynamic> cards = data['cards'];
        final Map scores = data['scores'];
        final int turn = data['currentTurn'];
        final bool isMyTurn = (turn == widget.myPlayerId);
        final int currentTurnCount = data['turnCount'] ?? 1;
        final int maxTurns = data['maxTurns'] ?? 30;

        // 勝者が決まったらリザルトを表示
        if (data['winner'] != 0) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _showResult(data['winner'], scores));
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0A3D14),
          appBar: AppBar(
            toolbarHeight: 50,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Room: ${widget.roomId} (P${widget.myPlayerId})",
                    style: const TextStyle(fontSize: 14)),
                Text("Turn: $currentTurnCount / $maxTurns",
                    style: const TextStyle(
                        fontSize: 12, color: Colors.yellowAccent)),
              ],
            ),
            backgroundColor: turn == 1 ? Colors.blue[900] : Colors.red[900],
          ),
          body: Column(
            children: [
              _buildHeader(isMyTurn, turn, scores),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: LayoutBuilder(builder: (context, constraints) {
                    return GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 13,
                        mainAxisSpacing: 2,
                        crossAxisSpacing: 2,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: cards.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _handleTap(index, data),
                          child: CardMini(
                            card: cards[index],
                            isMyTurn: isMyTurn,
                            pColor: turn == 1 ? Colors.blue : Colors.red,
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isMyTurn, int turn, Map scores) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.black26,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _scoreText(1, scores['1'], turn == 1),
          Text(isMyTurn ? "YOUR TURN" : "WAITING...",
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
          _scoreText(2, scores['2'], turn == 2),
        ],
      ),
    );
  }

  Widget _scoreText(int id, int score, bool active) {
    return Column(
      children: [
        Text("P$id",
            style: TextStyle(color: active ? Colors.white : Colors.white38)),
        Text("$score pt",
            style: TextStyle(
                color: active ? Colors.white : Colors.white38,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
      ],
    );
  }

  int _getCardPoint(String rank) {
    switch (rank) {
      case 'A':
        return 1;
      case 'J':
        return 11;
      case 'Q':
        return 12;
      case 'K':
        return 13;
      default:
        return int.tryParse(rank) ?? 0;
    }
  }

  // 勝利判定の共通ロジック
  int _calculateWinner(bool allTaken, bool isLimitReached, Map scores) {
    if (allTaken || isLimitReached) {
      int s1 = scores['1'] ?? 0;
      int s2 = scores['2'] ?? 0;
      if (s1 > s2) return 1;
      if (s2 > s1) return 2;
      return 3; // 引き分け
    }
    return 0; // 継続
  }

  Future<void> _handleTap(int index, Map<String, dynamic> data) async {
    if (_isProcessing || data['currentTurn'] != widget.myPlayerId) return;

    List<dynamic> currentCards = List.from(data['cards']);
    if (currentCards[index]['isFaceUp'] || currentCards[index]['isTaken'])
      return;
    if (data['winner'] != 0) return;

    setState(() => _isProcessing = true);
    final docRef =
        FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);
    int firstIdx = data['firstSelectedIndex'];

    if (firstIdx == -1) {
      // --- 1枚目の選択 ---
      currentCards[index]['isFaceUp'] = true;
      await docRef.update({'cards': currentCards, 'firstSelectedIndex': index});
      _isProcessing = false;
    } else {
      // --- 2枚目の選択 ---
      currentCards[index]['isFaceUp'] = true;
      await docRef.update({'cards': currentCards});

      bool isMatch =
          currentCards[firstIdx]['rank'] == currentCards[index]['rank'];
      int currentTurnCount = (data['turnCount'] ?? 0) + 1;
      int maxTurns = data['maxTurns'] ?? 30;
      Map<String, dynamic> newScores = Map.from(data['scores']);

      if (isMatch) {
        // ==========================================
        // ペア成立時
        // ==========================================
        await Future.delayed(const Duration(milliseconds: 600));
        currentCards[firstIdx]['isTaken'] = true;
        currentCards[index]['isTaken'] = true;

        // スコア加算
        int points = _getCardPoint(currentCards[index]['rank']);
        int oldScore = newScores[widget.myPlayerId.toString()] ?? 0;
        newScores[widget.myPlayerId.toString()] = oldScore + points;

        // 特殊効果
        String rank = currentCards[index]['rank'];
        if (rank == 'Q') {
          currentCards = GameEffects.applyQueenEffect(currentCards);
        } else if (rank == 'J') {
          currentCards = GameEffects.applyJackEffect(currentCards, 13);
        } else if (rank == '10') {
          currentCards = GameEffects.applyTenEffect(currentCards);
        } else if (rank == '9') {
          currentCards = GameEffects.applyNineEffect(currentCards, 13);
        }

        bool allTaken = currentCards.every((c) => c['isTaken']);
        bool isLimitReached = currentTurnCount >= maxTurns;
        int winner = _calculateWinner(allTaken, isLimitReached, newScores);

        // 更新 (ペア成立時はターンを継続させるのが一般的)
        await docRef.update({
          'cards': currentCards,
          'scores': newScores,
          'firstSelectedIndex': -1,
          'turnCount': currentTurnCount,
          'winner': winner,
          // ターンを交代させたい場合は 'currentTurn': widget.myPlayerId == 1 ? 2 : 1 を追加
        });
      } else {
        // ==========================================
        // ペア不成立時
        // ==========================================
        await Future.delayed(const Duration(milliseconds: 1000));
        currentCards[firstIdx]['isFaceUp'] = false;
        currentCards[index]['isFaceUp'] = false;

        bool isLimitReached = currentTurnCount >= maxTurns;
        int winner = _calculateWinner(false, isLimitReached, newScores);

        // ターンを交代
        int nextTurn = widget.myPlayerId == 1 ? 2 : 1;

        await docRef.update({
          'cards': currentCards,
          'firstSelectedIndex': -1,
          'currentTurn': nextTurn,
          'turnCount': currentTurnCount,
          'winner': winner
        });
      }
      _isProcessing = false;
    }
    if (mounted) setState(() {});
  }

  void _showResult(int winner, Map scores) {
    String title = "";
    String msg = "";

    if (winner == 3) {
      title = "DRAW";
      msg = "引き分けです！\nScore: ${scores['1']} - ${scores['2']}";
    } else if (winner == widget.myPlayerId) {
      title = "YOU WIN! 🎉";
      msg = "おめでとうございます！あなたの勝利です。\nScore: ${scores['1']} - ${scores['2']}";
    } else {
      title = "YOU LOSE... 💀";
      msg = "残念...相手の勝利です。\nScore: ${scores['1']} - ${scores['2']}";
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(title,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: (winner == widget.myPlayerId) ? Colors.blue : Colors.red,
                fontWeight: FontWeight.bold)),
        content: Text(msg, textAlign: TextAlign.center),
        actions: [
          Center(
            child: TextButton(
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                child: const Text("ロビーに戻る")),
          ),
        ],
      ),
    );
  }
}
