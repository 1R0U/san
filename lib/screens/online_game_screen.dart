import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'standby_screen.dart';
import '../services/firestore_service.dart';
import '../widgets/game_header.dart';
import '../widgets/game_grid.dart';
import '../widgets/game_effects.dart';
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
  Timestamp? _lastProcessedTimestamp;

  bool _isExchangeMode = false,
      _isCheckMode = false,
      _isPermanentCheckMode = false;
  int _targetCount = 0;
  List<int> _selectedForExchange = [], _tempRevealedIndices = [];

  // --- ★重要: 中断（退出）時のデータ削除判定 ---
  Future<void> _backToStandby() async {
    final docRef =
        FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);

    // 1. 自分の「ゲーム中」フラグを false にする
    final myGameField = widget.myPlayerId == 1 ? 'p1InGame' : 'p2InGame';
    await docRef.update({
      myGameField: false,
      'p1Ready': false,
      'p2Ready': false,
      'firstSelectedIndex': -1,
    });

    // 2. 相手もいないか確認する
    final snapshot = await docRef.get();
    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      final bool p1InGame = data['p1InGame'] ?? false;
      final bool p2InGame = data['p2InGame'] ?? false;

      // ★両方が対戦画面からいなくなったら、対戦データを完全初期化
      if (!p1InGame && !p2InGame) {
        await FirestoreService.resetRoomFully(widget.roomId);
      }
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (_) => StandbyScreen(
              roomId: widget.roomId, myPlayerId: widget.myPlayerId)),
    );
  }

  // 退出確認ダイアログ
  Future<void> _showExitConfirmation() async {
    final bool? shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("退出の確認"),
        content: const Text("対戦を中断して待機画面に戻りますか？\n（二人が戻るとデータはリセットされます）"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("キャンセル")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("戻る", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (shouldExit == true) await _backToStandby();
  }

  // エフェクト演出ロジック
  Future<void> _handleEffectTrigger(
      String effectRank, List<int> effectData, bool isMyTurn) async {
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

    if (isMyTurn) {
      if (effectRank == 'A' || effectRank == '6') {
        setState(() => _tempRevealedIndices = effectData);
        Future.delayed(const Duration(seconds: 8),
            () => setState(() => _tempRevealedIndices = []));
      }
      if (effectRank == '8')
        setState(() => {
              _isExchangeMode = true,
              _targetCount = 2,
              _selectedForExchange = []
            });
      else if (effectRank == '7')
        setState(() => {
              _isPermanentCheckMode = true,
              _targetCount = 3,
              _selectedForExchange = []
            });
      else if (effectRank == '4')
        setState(() =>
            {_isCheckMode = true, _targetCount = 3, _selectedForExchange = []});
      else if (effectRank == '3')
        setState(() => {
              _isPermanentCheckMode = true,
              _targetCount = 7,
              _selectedForExchange = []
            });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _showExitConfirmation();
      },
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists)
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final turn = data['currentTurn'] ?? 1;
          final isMyTurn = turn == widget.myPlayerId;
          final Map<String, dynamic> scores =
              Map<String, dynamic>.from(data['scores'] ?? {'1': 0, '2': 0});

          Timestamp? ts = data['effectTimestamp'];
          if (ts != null &&
              (_lastProcessedTimestamp == null ||
                  ts.compareTo(_lastProcessedTimestamp!) > 0)) {
            _lastProcessedTimestamp = ts;
            WidgetsBinding.instance.addPostFrameCallback((_) =>
                _handleEffectTrigger(data['latestEffect'] ?? '',
                    (data['effectData'] as List? ?? []).cast<int>(), isMyTurn));
          }

          if (data['winner'] != 0) {
            WidgetsBinding.instance.addPostFrameCallback(
                (_) => _showResult(data['winner'], scores));
          }

          String titleText = "Room: ${widget.roomId}";
          if (_isExchangeMode) titleText = "入れ替えるカードを選択";
          if (_isCheckMode) titleText = "透視するカードを選択";
          if (_isPermanentCheckMode) titleText = "永久透視するカードを選択";

          return Scaffold(
            backgroundColor: const Color(0xFF0A3D14),
            appBar: AppBar(
              toolbarHeight: 50,
              backgroundColor: turn == 1 ? Colors.blue[900] : Colors.red[900],
              leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _showExitConfirmation()),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titleText,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                  Text("Turn: ${data['turnCount']} / ${data['maxTurns']}",
                      style: const TextStyle(
                          fontSize: 11, color: Colors.yellowAccent)),
                ],
              ),
            ),
            body: Column(
              children: [
                GameHeader(turn: turn, scores: scores, isMyTurn: isMyTurn),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: GameGrid(
                        cards: data['cards'],
                        myPlayerId: widget.myPlayerId,
                        turn: turn,
                        firstSelectedIndex: data['firstSelectedIndex'] ?? -1,
                        highlightedIndices:
                            (data['highlightedIndices'] as List? ?? [])
                                .cast<int>(),
                        tempRevealedIndices: _tempRevealedIndices,
                        selectedForExchange: _selectedForExchange,
                        activeEffect: data['activeEffect'],
                        onTap: (i) => _handleTap(i, data)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleTap(int index, Map<String, dynamic> data) async {
    if (data['winner'] != 0 || _isProcessing || _tempRevealedIndices.isNotEmpty)
      return;
    final docRef =
        FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);

    if (_isCheckMode || _isPermanentCheckMode || _isExchangeMode) {
      if (_selectedForExchange.contains(index) ||
          data['cards'][index]['isFaceUp']) return;
      setState(() => _selectedForExchange.add(index));
      if (_selectedForExchange.length >= _targetCount) {
        if (_isCheckMode) {
          setState(
              () => _tempRevealedIndices = List.from(_selectedForExchange));
          Future.delayed(const Duration(seconds: 8),
              () => setState(() => _tempRevealedIndices = []));
        } else {
          setState(() => _isProcessing = true);
          List<dynamic> cards = List.from(data['cards']);
          if (_isPermanentCheckMode) {
            for (var i in _selectedForExchange) {
              Map<String, dynamic> c = Map<String, dynamic>.from(cards[i]);
              List<int> v = List<int>.from(c['permViewers'] ?? []);
              if (!v.contains(widget.myPlayerId)) v.add(widget.myPlayerId);
              c['permViewers'] = v;
              cards[i] = c;
            }
          } else if (_isExchangeMode) {
            cards =
                GameEffectsLogic.swapSpecificCards(cards, _selectedForExchange);
          }
          await docRef.update({'cards': cards});
          setState(() => _isProcessing = false);
        }
        setState(() => {
              _isCheckMode = false,
              _isPermanentCheckMode = false,
              _isExchangeMode = false,
              _selectedForExchange = []
            });
      }
      return;
    }

    if (data['currentTurn'] != widget.myPlayerId) return;
    List<dynamic> cards = List.from(data['cards']);
    if (cards[index]['isFaceUp'] || cards[index]['isTaken']) return;
    setState(() => _isProcessing = true);
    int first = data['firstSelectedIndex'] ?? -1;

    if (first == -1) {
      cards[index]['isFaceUp'] = true;
      await docRef.update({'cards': cards, 'firstSelectedIndex': index});
    } else {
      cards[index]['isFaceUp'] = true;
      await docRef.update({'cards': cards});
      bool match = cards[first]['rank'] == cards[index]['rank'];
      int nextCount = (data['turnCount'] ?? 1) + 1;
      Map<String, dynamic> scores = Map.from(data['scores']);

      if (match) {
        await Future.delayed(const Duration(milliseconds: 600));
        cards[first]['isTaken'] = cards[index]['isTaken'] = true;
        scores[widget.myPlayerId.toString()] =
            (scores[widget.myPlayerId.toString()] ?? 0) +
                _getPoint(cards[index]['rank']);
        String r = cards[index]['rank'];
        List<int> hIndices = [];
        String? effect;
        List<int> eData = [];
        if (r == 'Q')
          cards = GameEffectsLogic.applyQueenEffect(cards);
        else if (r == 'J')
          cards = GameEffectsLogic.applyJackEffect(cards);
        else if (r == '10') {
          var res = GameEffectsLogic.applyTenEffect(cards);
          cards = res['cards'];
          hIndices = res['indices'];
        } else if (r == '9') {
          cards = GameEffectsLogic.applyNineEffect(cards);
          effect = 'nine';
        } else if (r == '2') {
          var res = GameEffectsLogic.applyTwoEffect(scores, widget.myPlayerId);
          scores['1'] = res['1'];
          scores['2'] = res['2'];
        } else if (r == '6')
          eData = GameEffectsLogic.getRandomRevealIndices(
              cards, 3, widget.myPlayerId);
        else if (r == 'A')
          eData = GameEffectsLogic.getRandomRevealIndices(
              cards, 8, widget.myPlayerId);

        int win =
            (cards.every((c) => c['isTaken']) || nextCount > data['maxTurns'])
                ? (scores['1'] > scores['2']
                    ? 1
                    : (scores['2'] > scores['1'] ? 2 : 3))
                : 0;
        await docRef.update({
          'cards': cards,
          'scores': scores,
          'firstSelectedIndex': -1,
          'turnCount': nextCount,
          'winner': win,
          'highlightedIndices': hIndices,
          'activeEffect': effect,
          'latestEffect': r,
          'effectTimestamp': FieldValue.serverTimestamp(),
          'effectData': eData
        });

        if (hIndices.isNotEmpty || effect != null) {
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted)
              docRef.update({'highlightedIndices': [], 'activeEffect': null});
          });
        }
      } else {
        await Future.delayed(const Duration(milliseconds: 1000));
        cards[first]['isFaceUp'] = cards[index]['isFaceUp'] = false;
        int win = (nextCount > data['maxTurns'])
            ? (scores['1'] > scores['2']
                ? 1
                : (scores['2'] > scores['1'] ? 2 : 3))
            : 0;
        await docRef.update({
          'cards': cards,
          'firstSelectedIndex': -1,
          'currentTurn': widget.myPlayerId == 1 ? 2 : 1,
          'turnCount': nextCount,
          'winner': win
        });
      }
    }
    setState(() => _isProcessing = false);
  }

  int _getPoint(String r) {
    if (r == 'A') return 1;
    if (r == 'J') return 11;
    if (r == 'Q') return 12;
    if (r == 'K') return 13;
    return int.tryParse(r) ?? 0;
  }

  void _showResult(int win, Map<String, dynamic> s) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => AlertDialog(
                title: Text(win == 3
                    ? "引き分け"
                    : (win == widget.myPlayerId ? "勝利！" : "敗北...")),
                content: Text("${s['1']} - ${s['2']}"),
                actions: [
                  TextButton(
                      onPressed: () async {
                        await FirestoreService.resetBoardOnly(widget.roomId);
                        if (mounted)
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => StandbyScreen(
                                      roomId: widget.roomId,
                                      myPlayerId: widget.myPlayerId)));
                      },
                      child: const Text("再戦"))
                ]));
  }
}
