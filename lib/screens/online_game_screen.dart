import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/card_mini.dart';
import '../widgets/game_effects.dart'; // 演出用
import '../widgets/card_effects_widgets.dart'; // ロジック用

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
  Timestamp? _lastProcessedTimestamp;

  // --- モード管理変数 ---
  bool _isExchangeMode = false; // 8用
  bool _isCheckMode = false; // 4用
  bool _isPermanentCheckMode = false; // 3, 7用

  int _targetCount = 0;
  List<int> _selectedForExchange = [];

  // --- 透視・表示用変数 ---
  List<int> _tempRevealedIndices = [];

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

  // --- モード開始メソッド ---
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

  void _startReveal(List<int> indices) {
    setState(() => _tempRevealedIndices = indices);
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) setState(() => _tempRevealedIndices = []);
    });
  }

  // ★ここが修正ポイント: 自分か相手かを判定して処理を分ける
  Future<void> _handleEffectTrigger(
      String effectRank, List<int> effectData, bool isMyTurn) async {
    // 1. 演出ダイアログは「全員」に見せる (文言は isMyTurn で切り替え)
    if (effectRank == 'Q')
      await showQueenEffect(context, isSelf: isMyTurn);
    else if (effectRank == 'J')
      await showJackEffect(context, isSelf: isMyTurn);
    else if (effectRank == '10')
      await showTenEffect(context, isSelf: isMyTurn);
    else if (effectRank == '9')
      await showNineEffect(context, isSelf: isMyTurn);
    else if (effectRank == '8')
      await showExchangeEightEffect(context, isSelf: isMyTurn);
    else if (effectRank == '7')
      await showSevenEffect(context, isSelf: isMyTurn);
    else if (effectRank == '6')
      await showRevealEffect(context, "6", 3, isSelf: isMyTurn);
    else if (effectRank == '4')
      await showCheckEffect(context, isSelf: isMyTurn);
    else if (effectRank == '3')
      await showPermanentRevealEffect(context, 7, isSelf: isMyTurn);
    else if (effectRank == '2')
      await showStealTwoEffect(context, isSelf: isMyTurn);
    else if (effectRank == 'A')
      await showRevealEffect(context, "A", 8, isSelf: isMyTurn);

    // 2. 「自分のターン」の時だけ実行する処理
    if (isMyTurn) {
      // 透視実行
      if (effectRank == 'A' || effectRank == '6') {
        _startReveal(effectData);
      }

      // 選択モードへの移行
      if (effectRank == '8')
        _enterExchangeMode(2);
      else if (effectRank == '7')
        _enterPermanentCheckMode(3);
      else if (effectRank == '4')
        _enterCheckMode(3);
      else if (effectRank == '3') _enterPermanentCheckMode(7);
    }
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
        final int maxTurns = data['maxTurns'] ?? 50;
        final int firstSelectedIndex = data['firstSelectedIndex'] ?? -1;
        final List<int> highlightedIndices =
            (data['highlightedIndices'] as List? ?? []).cast<int>();
        final String? effectType = data['activeEffect'];

        // エフェクト検知ロジック
        Timestamp? serverTimestamp = data['effectTimestamp'];
        String? serverEffect = data['latestEffect'];
        List<int> serverEffectData =
            (data['effectData'] as List? ?? []).cast<int>();

        if (serverTimestamp != null && serverEffect != null) {
          // 初回ロード時は処理せずタイムスタンプだけ同期
          if (_lastProcessedTimestamp == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _lastProcessedTimestamp = serverTimestamp;
                });
              }
            });
          }
          // 新しいエフェクトが来た時だけ実行
          else if (serverTimestamp.compareTo(_lastProcessedTimestamp!) > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _lastProcessedTimestamp = serverTimestamp;
                });
                _handleEffectTrigger(serverEffect, serverEffectData, isMyTurn);
              }
            });
          }
        }

        if (data['winner'] != 0) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _showResult(data['winner'], scores));
        }

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
                      Map displayCard = Map.from(cards[index]);
                      List<dynamic> permViewers =
                          displayCard['permViewers'] ?? [];
                      bool isPermanentlyRevealedToMe =
                          permViewers.contains(widget.myPlayerId);

                      Color? hColor;

                      if (_selectedForExchange.contains(index)) {
                        if (_isExchangeMode)
                          hColor = Colors.redAccent;
                        else if (_isCheckMode)
                          hColor = Colors.cyanAccent;
                        else if (_isPermanentCheckMode) hColor = Colors.orange;
                      } else if (index == firstSelectedIndex) {
                        hColor = Colors.redAccent;
                      } else if (_tempRevealedIndices.contains(index)) {
                        hColor = Colors.pinkAccent;
                      } else if (highlightedIndices.contains(index)) {
                        hColor = Colors.yellowAccent;
                      } else if (effectType == 'nine') {
                        hColor = _getNineZoneColor(index);
                      } else if (isPermanentlyRevealedToMe) {
                        hColor = Colors.orange;
                      }

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

    if (_tempRevealedIndices.isNotEmpty) return;

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

    if (_isPermanentCheckMode) {
      if (_selectedForExchange.contains(index) ||
          data['cards'][index]['isFaceUp'] == true) return;
      setState(() => _selectedForExchange.add(index));
      if (_selectedForExchange.length >= _targetCount) {
        setState(() => _isProcessing = true);
        final docRef =
            FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);
        List<dynamic> cards = List.from(data['cards']);
        for (int idx in _selectedForExchange) {
          Map<String, dynamic> card = Map.from(cards[idx]);
          List<dynamic> viewers = List.from(card['permViewers'] ?? []);
          if (!viewers.contains(widget.myPlayerId))
            viewers.add(widget.myPlayerId);
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
        int maxTurns = data['maxTurns'] ?? 50;
        Map<String, dynamic> newScores = Map.from(data['scores']);

        if (isMatch) {
          await Future.delayed(const Duration(milliseconds: 600));
          cards[firstIdx]['isTaken'] = true;
          cards[index]['isTaken'] = true;
          int points = _getCardPoint(rank2);
          newScores[widget.myPlayerId.toString()] =
              (newScores[widget.myPlayerId.toString()] ?? 0) + points;

          String rank = rank2;
          List<int> highlightIndices = [];
          String? activeEffect;
          List<int> effectData = [];

          if (rank == 'Q') {
            cards = GameEffectsLogic.applyQueenEffect(cards);
          } else if (rank == 'J') {
            cards = GameEffectsLogic.applyJackEffect(cards);
          } else if (rank == '10') {
            var result = GameEffectsLogic.applyTenEffect(cards);
            cards = result['cards'];
            highlightIndices = result['indices'];
          } else if (rank == '9') {
            cards = GameEffectsLogic.applyNineEffect(cards);
            activeEffect = 'nine';
          } else if (rank == '2') {
            Map<String, int> stolenResult =
                GameEffectsLogic.applyTwoEffect(newScores, widget.myPlayerId);
            newScores['1'] = stolenResult['1'];
            newScores['2'] = stolenResult['2'];
          } else if (rank == '6') {
            effectData = GameEffectsLogic.getRandomRevealIndices(
                cards, 3, widget.myPlayerId);
          } else if (rank == 'A') {
            effectData = GameEffectsLogic.getRandomRevealIndices(
                cards, 8, widget.myPlayerId);
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
            'latestEffect': rank,
            'effectTimestamp': FieldValue.serverTimestamp(),
            'effectData': effectData,
          });

          if (highlightIndices.isNotEmpty || activeEffect != null) {
            Future.delayed(const Duration(seconds: 5), () {
              if (mounted)
                docRef.update({'highlightedIndices': [], 'activeEffect': null});
            });
          }
          _isProcessing = false;
        } else {
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
              style: const TextStyle(color: Colors.white, fontSize: 12)),
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
