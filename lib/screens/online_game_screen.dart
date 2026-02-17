import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/card_mini.dart';
import '../widgets/game_effects.dart'; // 演出用
import '../widgets/card_effects_widgets.dart'; // ロジック用 (GameEffectsLogic)

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

  // --- モード管理変数 ---
  bool _isExchangeMode = false; // 8用
  bool _isCheckMode = false; // 4用
  bool _isPermanentCheckMode = false; // 3用（永久透視選択）

  int _targetCount = 0; // 選択が必要な枚数
  List<int> _selectedForExchange = [];

  // --- 透視・表示用変数 ---
  List<int> _tempRevealedIndices = []; // A, 6, 7, 4用 (一時的)
  // ★削除: _permanentRevealedIndices (位置依存のため廃止し、カードデータ自体に保存します)

  // 9のエフェクト用色分け
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

  // --- モード開始メソッド群 ---

  void _enterExchangeMode(int count) {
    setState(() {
      _isExchangeMode = true;
      _isCheckMode = false;
      _isPermanentCheckMode = false;
      _targetCount = count;
      _selectedForExchange = [];
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("交換するカードを $count 枚選んでください")));
  }

  void _enterCheckMode(int count) {
    setState(() {
      _isCheckMode = true;
      _isExchangeMode = false;
      _isPermanentCheckMode = false;
      _targetCount = count;
      _selectedForExchange = [];
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("中身を確認したいカードを $count 枚選んでください")));
  }

  // 3用: 永久透視選択モード
  void _enterPermanentCheckMode(int count) {
    setState(() {
      _isPermanentCheckMode = true;
      _isExchangeMode = false;
      _isCheckMode = false;
      _targetCount = count;
      _selectedForExchange = [];
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("ずっと見たいカードを $count 枚選んでください")));
  }

  // 一時透視開始（8秒）
  void _startReveal(List<int> indices) {
    setState(() => _tempRevealedIndices = indices);
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) setState(() => _tempRevealedIndices = []);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final List<dynamic> cards = data['cards'] ?? [];
        final Map scores = data['scores'] ?? {'1': 0, '2': 0};
        final int turn = data['currentTurn'] ?? 1;
        final bool isMyTurn = (turn == widget.myPlayerId);
        final int currentTurnCount = data['turnCount'] ?? 1;

        // 1枚目に選ばれているカードの場所を取得
        final int firstSelectedIndex = data['firstSelectedIndex'] ?? -1;

        final List<int> highlightedIndices =
            (data['highlightedIndices'] as List? ?? []).cast<int>();
        final String? effectType = data['activeEffect'];

        if (data['winner'] != 0) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _showResult(data['winner'], scores));
        }

        // AppBarのタイトル制御
        String titleText = "Room: ${widget.roomId} (P${widget.myPlayerId})";
        Color titleColor = Colors.white;
        int remaining = _targetCount - _selectedForExchange.length;

        if (_isExchangeMode) {
          titleText = "交換対象を選択中: 残り ${remaining}枚";
          titleColor = Colors.orangeAccent;
        } else if (_isCheckMode) {
          titleText = "確認対象を選択中: 残り ${remaining}枚";
          titleColor = Colors.cyanAccent;
        } else if (_isPermanentCheckMode) {
          titleText = "永久透視を選択中: 残り ${remaining}枚";
          titleColor = Colors.orange;
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0A3D14),
          appBar: AppBar(
            toolbarHeight: 50,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titleText,
                    style: TextStyle(
                        fontSize: 14,
                        color: titleColor,
                        fontWeight: FontWeight.bold)),
                Text("Turn: $currentTurnCount",
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
                  child: GridView.builder(
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
                      // ★カードデータの取得と、自分に見えているかの判定
                      Map displayCard = Map.from(cards[index]);
                      List<dynamic> permViewers =
                          displayCard['permViewers'] ?? [];
                      bool isPermanentlyRevealedToMe =
                          permViewers.contains(widget.myPlayerId);

                      Color? hColor;

                      // --- 色決めの優先順位 ---

                      // 1. 選択モード中の選択色 (最優先)
                      if (_selectedForExchange.contains(index)) {
                        if (_isExchangeMode)
                          hColor = Colors.redAccent;
                        else if (_isCheckMode)
                          hColor = Colors.cyanAccent;
                        else if (_isPermanentCheckMode) hColor = Colors.orange;
                      }
                      // 2. 現在のターンで1枚目に選んでいるカード (赤色)
                      else if (index == firstSelectedIndex) {
                        hColor = Colors.redAccent;
                      }
                      // 3. ★一時透視中のカード (ピンクで表示)
                      else if (_tempRevealedIndices.contains(index)) {
                        hColor = Colors.pinkAccent;
                      }
                      // 4. 特殊効果によるハイライト (10の効果)
                      else if (highlightedIndices.contains(index)) {
                        hColor = Colors.yellowAccent;
                      }
                      // 5. 9の効果（エリア色分け）
                      else if (effectType == 'nine') {
                        hColor = _getNineZoneColor(index);
                      }
                      // 6. ★永久透視済みのカード (オレンジ)
                      // 位置リストではなく、カードデータを見るので移動しても色がついてくる！
                      else if (isPermanentlyRevealedToMe) {
                        hColor = Colors.orange;
                      }

                      // 透視ロジック
                      // 一時透視 または 永久透視(自分に対して) なら表向ける
                      if (_tempRevealedIndices.contains(index) ||
                          isPermanentlyRevealedToMe) {
                        displayCard['isFaceUp'] = true;
                      }

                      return GestureDetector(
                        onTap: () => _handleTap(index, data),
                        child: CardMini(
                          card: displayCard,
                          isMyTurn: isMyTurn,
                          pColor: turn == 1 ? Colors.blue : Colors.red,
                          highlightColor: hColor,
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

  Future<void> _handleTap(int index, Map<String, dynamic> data) async {
    if (data['winner'] != 0) return;

    // --- 4: 確認モード ---
    if (_isCheckMode) {
      if (_selectedForExchange.contains(index) ||
          data['cards'][index]['isFaceUp'] == true) return;
      setState(() => _selectedForExchange.add(index));
      if (_selectedForExchange.length >= _targetCount) {
        _startReveal(List<int>.from(_selectedForExchange));
        setState(() {
          _isCheckMode = false;
          _selectedForExchange = [];
        });
      }
      return;
    }

    // --- 3: 永久透視選択モード ---
    if (_isPermanentCheckMode) {
      if (_selectedForExchange.contains(index) ||
          data['cards'][index]['isFaceUp'] == true) return;

      setState(() => _selectedForExchange.add(index));

      if (_selectedForExchange.length >= _targetCount) {
        setState(() => _isProcessing = true);

        final docRef =
            FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);
        List<dynamic> cards = List.from(data['cards']);

        // ★修正: 選んだカードのデータ内に自分のIDを追加して保存 (これにより移動しても追従する)
        for (int idx in _selectedForExchange) {
          Map<String, dynamic> card = Map.from(cards[idx]);
          List<dynamic> viewers = List.from(card['permViewers'] ?? []);
          if (!viewers.contains(widget.myPlayerId)) {
            viewers.add(widget.myPlayerId);
          }
          card['permViewers'] = viewers;
          cards[idx] = card;
        }

        await docRef.update({'cards': cards});

        setState(() {
          _isPermanentCheckMode = false;
          _selectedForExchange = [];
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("選択したカードがずっと見えるようになりました")));
      }
      return;
    }

    // --- 8: 交換モード ---
    if (_isExchangeMode) {
      if (_selectedForExchange.contains(index)) return;
      setState(() => _selectedForExchange.add(index));
      if (_selectedForExchange.length >= _targetCount) {
        setState(() => _isProcessing = true);
        final docRef =
            FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);
        List<dynamic> cards = List.from(data['cards']);
        cards = GameEffectsLogic.swapSpecificCards(cards, _selectedForExchange);
        await docRef.update({'cards': cards});
        setState(() {
          _isExchangeMode = false;
          _selectedForExchange = [];
          _isProcessing = false;
        });
      }
      return;
    }

    // --- 通常のゲーム進行タップ ---
    if (_isProcessing || data['currentTurn'] != widget.myPlayerId) return;
    List<dynamic> cards = List.from(data['cards']);
    if (cards[index]['isFaceUp'] || cards[index]['isTaken']) return;

    setState(() => _isProcessing = true);
    final docRef =
        FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);
    int firstIdx = data['firstSelectedIndex'];

    try {
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
        Map<String, dynamic> newScores = Map.from(data['scores']);

        if (isMatch) {
          // ■ 正解時
          await Future.delayed(const Duration(milliseconds: 600));
          cards[firstIdx]['isTaken'] = true;
          cards[index]['isTaken'] = true;
          int points = _getCardPoint(rank2);
          newScores[widget.myPlayerId.toString()] =
              (newScores[widget.myPlayerId.toString()] ?? 0) + points;

          // ★ 特殊効果分岐
          String rank = rank2;
          List<int> highlightIndices = [];
          String? activeEffect;

          if (rank == 'Q') {
            if (mounted) await showQueenEffect(context);
            cards = GameEffectsLogic.applyQueenEffect(cards);
          } else if (rank == 'J') {
            if (mounted) await showJackEffect(context);
            cards = GameEffectsLogic.applyJackEffect(cards);
          } else if (rank == '10') {
            if (mounted) await showTenEffect(context);
            var result = GameEffectsLogic.applyTenEffect(cards);
            cards = result['cards'];
            highlightIndices = result['indices'];
          } else if (rank == '9') {
            if (mounted) await showNineEffect(context);
            cards = GameEffectsLogic.applyNineEffect(cards);
            activeEffect = 'nine';
          } else if (rank == '8') {
            if (mounted) await showExchangeEightEffect(context);
            _enterExchangeMode(2);
          } else if (rank == '7') {
            if (mounted) await showSevenEffect(context);
            var result = GameEffectsLogic.applySevenEffect(cards);
            cards = result['cards'];
            _startReveal(List<int>.from(result['targetIndices']));
          } else if (rank == '6') {
            if (mounted) await showRevealEffect(context, "6", 3);
            // ★修正: 自分のIDを渡して、永久透視済みのものを除外してもらう
            _startReveal(GameEffectsLogic.getRandomRevealIndices(
                cards, 3, widget.myPlayerId));
          } else if (rank == '4') {
            if (mounted) await showCheckEffect(context);
            _enterCheckMode(3);
          } else if (rank == '3') {
            int revealCount = 7;
            if (mounted) await showPermanentRevealEffect(context, revealCount);
            _enterPermanentCheckMode(revealCount);
          } else if (rank == '2') {
            if (mounted) await showStealTwoEffect(context);
            Map<String, int> stolenResult =
                GameEffectsLogic.applyTwoEffect(newScores, widget.myPlayerId);
            newScores['1'] = stolenResult['1'];
            newScores['2'] = stolenResult['2'];
          } else if (rank == 'A') {
            if (mounted) await showRevealEffect(context, "A", 8);
            // ★修正: 自分のIDを渡して、永久透視済みのものを除外してもらう
            _startReveal(GameEffectsLogic.getRandomRevealIndices(
                cards, 8, widget.myPlayerId));
          }

          int winner = 0;
          if (cards.every((c) => c['isTaken']) || currentTurnCount > maxTurns) {
            int s1 = newScores['1'] is int
                ? newScores['1']
                : (newScores['1'] as num).toInt();
            int s2 = newScores['2'] is int
                ? newScores['2']
                : (newScores['2'] as num).toInt();
            winner = s1 > s2 ? 1 : (s2 > s1 ? 2 : 3);
          }

          await docRef.update({
            'cards': cards,
            'scores': newScores,
            'firstSelectedIndex': -1,
            'turnCount': currentTurnCount,
            'winner': winner,
            'highlightedIndices': highlightIndices,
            'activeEffect': activeEffect,
          });

          if (highlightIndices.isNotEmpty || activeEffect != null) {
            Future.delayed(const Duration(seconds: 5), () {
              if (mounted)
                docRef.update({'highlightedIndices': [], 'activeEffect': null});
            });
          }
          _isProcessing = false;
        } else {
          // 不正解
          await Future.delayed(const Duration(milliseconds: 1000));
          cards[firstIdx]['isFaceUp'] = false;
          cards[index]['isFaceUp'] = false;
          int winner = 0;
          if (currentTurnCount > maxTurns) {
            int s1 = newScores['1'];
            int s2 = newScores['2'];
            winner = s1 > s2 ? 1 : (s2 > s1 ? 2 : 3);
          }
          await docRef.update({
            'cards': cards,
            'firstSelectedIndex': -1,
            'currentTurn': widget.myPlayerId == 1 ? 2 : 1,
            'turnCount': currentTurnCount,
            'winner': winner,
          });
          _isProcessing = false;
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _isProcessing = false);
    }
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

  Widget _scoreText(int id, dynamic score, bool active) {
    return Column(children: [
      Text("P$id",
          style: TextStyle(color: active ? Colors.white : Colors.white38)),
      Text("$score pt",
          style: TextStyle(
              color: active ? Colors.white : Colors.white38,
              fontSize: 18,
              fontWeight: FontWeight.bold)),
    ]);
  }

  int _getCardPoint(String? r) {
    if (r == null) return 0;
    if (r == 'A') return 1;
    if (r == 'J') return 11;
    if (r == 'Q') return 12;
    if (r == 'K') return 13;
    return int.tryParse(r) ?? 0;
  }

  void _showResult(int winner, Map scores) {
    String title = winner == 3
        ? "DRAW"
        : (winner == widget.myPlayerId ? "YOU WIN! 🎉" : "YOU LOSE... 💀");
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(title,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: winner == widget.myPlayerId ? Colors.blue : Colors.red,
                fontWeight: FontWeight.bold)),
        content: Text("Score: ${scores['1']} - ${scores['2']}",
            textAlign: TextAlign.center),
        actions: [
          Center(
              child: TextButton(
                  onPressed: () =>
                      Navigator.popUntil(context, (r) => r.isFirst),
                  child: const Text("ロビーへ")))
        ],
      ),
    );
  }
}
