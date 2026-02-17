import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/card_mini.dart';
import '../widgets/game_effects.dart';
import '../widgets/card_effects_widgets.dart';

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

        if (!snapshot.data!.exists) {
          return const Scaffold(body: Center(child: Text("部屋が見つかりません")));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final List<dynamic> cards = data['cards'] ?? [];
        final Map scores = data['scores'] ?? {'1': 0, '2': 0};
        final int turn = data['currentTurn'] ?? 1;
        final bool isMyTurn = (turn == widget.myPlayerId);
        final int currentTurnCount = data['turnCount'] ?? 1;
        final int maxTurns = data['maxTurns'] ?? 30;

        // ★追加：Firestoreからハイライト情報を取得
        final List<dynamic> rawHighlights = data['highlightedIndices'] ?? [];
        final List<int> highlightedIndices = rawHighlights.cast<int>();

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
                            // ★追加：このカードがハイライト対象か判定して渡す
                            isHighlighted: highlightedIndices.contains(index),
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

  // (_buildHeader, _scoreText, _getCardPoint は変更なし)
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

  int _getCardPoint(String? rank) {
    if (rank == null) return 0;
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

  Future<void> _handleTap(int index, Map<String, dynamic> data) async {
    if (_isProcessing || data['currentTurn'] != widget.myPlayerId) return;

    List<dynamic> cards = List.from(data['cards']);

    if (cards[index]['isFaceUp'] || cards[index]['isTaken']) return;
    if (data['winner'] != 0) return;

    setState(() => _isProcessing = true);

    try {
      final docRef =
          FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);
      int firstIdx = data['firstSelectedIndex'];

      if (firstIdx == -1) {
        cards[index]['isFaceUp'] = true;
        await docRef.update({'cards': cards, 'firstSelectedIndex': index});
        _isProcessing = false;
      } else {
        cards[index]['isFaceUp'] = true;
        await docRef.update({'cards': cards});

        String rank1 = cards[firstIdx]['rank'] ?? "";
        String rank2 = cards[index]['rank'] ?? "";
        bool isMatch = (rank1 == rank2) && (rank1 != "");

        int currentTurnCount = (data['turnCount'] ?? 0) + 1;
        int maxTurns = data['maxTurns'] ?? 30;

        if (isMatch) {
          // ■ 正解
          await Future.delayed(const Duration(milliseconds: 600));
          cards[firstIdx]['isTaken'] = true;
          cards[index]['isTaken'] = true;

          int points = _getCardPoint(cards[index]['rank']);
          int newScore =
              (data['scores'][widget.myPlayerId.toString()] ?? 0) + points;

          // ===============================================
          // ★ 特殊効果の分岐
          // ===============================================
          String rank = cards[index]['rank'];
          List<int> highlightIndices = []; // ★ハイライトする場所リスト

          if (rank == 'Q') {
            if (mounted) await showQueenEffect(context);
            cards = GameEffectsLogic.applyQueenEffect(cards);
          } else if (rank == 'J') {
            if (mounted) await showJackEffect(context);
            cards = GameEffectsLogic.applyJackEffect(cards);
          } else if (rank == '10') {
            if (mounted) await showTenEffect(context);
            // ★修正: 戻り値が Map になったので受け取り方を変える
            var result = GameEffectsLogic.applyTenEffect(cards);
            cards = result['cards'];
            highlightIndices = result['indices']; // 変更された場所を受け取る
          } else if (rank == '9') {
            if (mounted) await showNineEffect(context);
            cards = GameEffectsLogic.applyNineEffect(cards);
          }
          // ===============================================

          Map<String, dynamic> newScores = Map.from(data['scores']);
          newScores[widget.myPlayerId.toString()] = newScore;

          int winner = 0;
          bool allTaken = cards.every((c) => c['isTaken']);
          bool isLimitReached = currentTurnCount > maxTurns;
          if (allTaken || isLimitReached) {
            if (newScores['1'] > newScores['2'])
              winner = 1;
            else if (newScores['2'] > newScores['1'])
              winner = 2;
            else
              winner = 3;
          }

          // ★ Firestore更新：ハイライト情報も含める
          await docRef.update({
            'cards': cards,
            'scores': newScores,
            'firstSelectedIndex': -1,
            'turnCount': currentTurnCount,
            'winner': winner,
            'highlightedIndices': highlightIndices, // ★ここで保存
          });

          _isProcessing = false;

          // ★追加：2秒後にハイライトを消す処理
          if (highlightIndices.isNotEmpty) {
            Future.delayed(const Duration(seconds: 2), () async {
              // まだゲームが続いていれば消す
              await docRef.update({'highlightedIndices': []});
            });
          }
        } else {
          // ■ 不正解（変更なし）
          await Future.delayed(const Duration(milliseconds: 1000));
          cards[firstIdx]['isFaceUp'] = false;
          cards[index]['isFaceUp'] = false;

          int winner = 0;
          bool isLimitReached = currentTurnCount > maxTurns;
          if (isLimitReached) {
            int s1 = data['scores']['1'];
            int s2 = data['scores']['2'];
            if (s1 > s2)
              winner = 1;
            else if (s2 > s1)
              winner = 2;
            else
              winner = 3;
          }

          await docRef.update({
            'cards': cards,
            'firstSelectedIndex': -1,
            'currentTurn': widget.myPlayerId == 1 ? 2 : 1,
            'turnCount': currentTurnCount,
            'winner': winner
          });
          _isProcessing = false;
        }
      }
    } catch (e) {
      debugPrint("エラーが発生しました: $e");
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showResult(int winner, Map scores) {
    // (省略: 前回と同じ)
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
