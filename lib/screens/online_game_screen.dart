import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/card_effects_widgets.dart';
import '../widgets/game_header.dart';
import '../widgets/game_grid.dart';
import '../services/firestore_service.dart';
import '../models/player_model.dart';
import 'standby_screen.dart';

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

  // 特殊モード（3, 4, 7, 8の効果）の状態管理
  bool _isExchangeMode = false;
  bool _isCheckMode = false;
  bool _isPermanentCheckMode = false;
  int _targetCount = 0;
  List<int> _selectedIndices = [];
  List<int> _tempRevealed = []; // A, 6の効果用

  // --- 待機画面へ戻る ---
  Future<void> _backToStandby() async {
    await FirestoreService.leaveRoomAndCleanup(
        widget.roomId, widget.myPlayerId);
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  // --- エフェクト演出のトリガー ---
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

    if (isMyTurn && (effectRank == 'A' || effectRank == '6')) {
      setState(() => _tempRevealed = effectData);
      Future.delayed(const Duration(seconds: 8), () {
        if (mounted) setState(() => _tempRevealed = []);
      });
    }
  }

  // --- メインタップ処理 ---
  Future<void> _handleTap(int index, Map<String, dynamic> data) async {
    if (_isProcessing || _tempRevealed.isNotEmpty) return;

    if (_isExchangeMode || _isCheckMode || _isPermanentCheckMode) {
      _handleSpecialModeSelection(index, data);
      return;
    }

    if (data['currentTurn'] != widget.myPlayerId) return;

    List<dynamic> cards = List.from(data['cards']);
    if (cards[index]['isFaceUp'] || cards[index]['isTaken']) return;

    setState(() => _isProcessing = true);
    final docRef =
        FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);
    int first = data['firstSelectedIndex'] ?? -1;

    try {
      if (first == -1) {
        cards[index]['isFaceUp'] = true;
        await docRef.update({'cards': cards, 'firstSelectedIndex': index});
      } else {
        cards[index]['isFaceUp'] = true;
        await docRef.update({'cards': cards});

        await Future.delayed(const Duration(milliseconds: 1200));

        bool match = cards[first]['rank'] == cards[index]['rank'];
        Map<String, dynamic> playersMap =
            Map<String, dynamic>.from(data['players']);

        if (match) {
          String r = cards[index]['rank'];
          cards[first]['isTaken'] = cards[index]['isTaken'] = true;
          playersMap[widget.myPlayerId.toString()]['score'] +=
              GameEffectsLogic.getCardPoints(r);

          List<int> hIdx = [];
          String? activeEffect;
          List<int> eData = [];
          if (r == 'Q')
            cards = GameEffectsLogic.applyQueenEffect(cards);
          else if (r == 'J')
            cards = GameEffectsLogic.applyJackEffect(cards);
          else if (r == '10') {
            var res = GameEffectsLogic.applyTenEffect(cards);
            cards = res['cards'];
            hIdx = res['indices'];
          } else if (r == '9') {
            cards = GameEffectsLogic.applyNineEffect(cards);
            activeEffect = 'nine';
          } else if (r == '2')
            playersMap =
                GameEffectsLogic.applyTwoEffect(playersMap, widget.myPlayerId);
          else if (r == '6' || r == 'A')
            eData = GameEffectsLogic.getRandomRevealIndices(
                cards, r == 'A' ? 8 : 3, widget.myPlayerId);

          _checkSpecialActionNeeded(r);
          await docRef.update({
            'cards': cards,
            'players': playersMap,
            'firstSelectedIndex': -1,
            'latestEffect': r,
            'effectTimestamp': FieldValue.serverTimestamp(),
            'effectData': eData,
            'highlightedIndices': hIdx,
            'activeEffect': activeEffect,
            'winner': cards.every((c) => c['isTaken']) ? widget.myPlayerId : 0,
          });
        } else {
          cards[first]['isFaceUp'] = cards[index]['isFaceUp'] = false;
          int nextTurn =
              GameEffectsLogic.getNextTurn(widget.myPlayerId, playersMap);
          await docRef.update({
            'cards': cards,
            'firstSelectedIndex': -1,
            'currentTurn': nextTurn,
            'turnCount': (data['turnCount'] ?? 1) + 1
          });
        }
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _handleSpecialModeSelection(int index, Map<String, dynamic> data) async {
    if (_selectedIndices.contains(index) || data['cards'][index]['isFaceUp'])
      return;
    setState(() => _selectedIndices.add(index));
    if (_selectedIndices.length >= _targetCount) {
      final docRef =
          FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);
      List<dynamic> cards = List.from(data['cards']);
      if (_isCheckMode) {
        setState(() => _tempRevealed = List.from(_selectedIndices));
        Future.delayed(const Duration(seconds: 8),
            () => setState(() => _tempRevealed = []));
      } else {
        if (_isPermanentCheckMode) {
          for (var i in _selectedIndices) {
            Map<String, dynamic> c = Map<String, dynamic>.from(cards[i]);
            List<int> v = List<int>.from(c['permViewers'] ?? []);
            if (!v.contains(widget.myPlayerId)) v.add(widget.myPlayerId);
            c['permViewers'] = v;
            cards[i] = c;
          }
        } else if (_isExchangeMode)
          cards = GameEffectsLogic.swapSpecificCards(cards, _selectedIndices);
        await docRef.update({'cards': cards});
      }
      setState(() {
        _isCheckMode = false;
        _isPermanentCheckMode = false;
        _isExchangeMode = false;
        _selectedIndices = [];
      });
    }
  }

  void _checkSpecialActionNeeded(String r) {
    setState(() {
      _selectedIndices = [];
      if (r == '8') {
        _isExchangeMode = true;
        _targetCount = 2;
      } else if (r == '4') {
        _isCheckMode = true;
        _targetCount = 3;
      } else if (r == '7') {
        _isPermanentCheckMode = true;
        _targetCount = 3;
      } else if (r == '3') {
        _isPermanentCheckMode = true;
        _targetCount = 7;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final exit = await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
                    title: const Text("確認"),
                    content: const Text("退出しますか？"),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text("いいえ")),
                      TextButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text("はい"))
                    ]));
        if (exit == true) await _backToStandby();
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
          final players = Map<String, dynamic>.from(data['players'] ?? {});
          final me = players[widget.myPlayerId.toString()] as Map<String, dynamic>?;
          final isTallLayout = (me?['layoutMode'] ?? 'wide') == 'tall';
          final turn = data['currentTurn'] ?? 1;
          final isMyTurn = turn == widget.myPlayerId;
          Timestamp? ts = data['effectTimestamp'];
          if (ts != null &&
              (_lastProcessedTimestamp == null ||
                  ts.compareTo(_lastProcessedTimestamp!) > 0)) {
            _lastProcessedTimestamp = ts;
            WidgetsBinding.instance.addPostFrameCallback((_) =>
                _handleEffectTrigger(data['latestEffect'] ?? '',
                    (data['effectData'] as List? ?? []).cast<int>(), isMyTurn));
          }
          return Scaffold(
            backgroundColor: const Color(0xFF0A3D14),
            appBar: AppBar(
              toolbarHeight: 50,
              backgroundColor: isMyTurn ? Colors.blue[900] : Colors.red[900],
              title: Text("TURN: ${data['turnCount']} / 50",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              centerTitle: true,
              actions: [
                IconButton(
                  tooltip: isTallLayout ? '横長表示に切替' : '縦長表示に切替',
                  onPressed: () async {
                    final next = isTallLayout ? 'wide' : 'tall';
                    await FirebaseFirestore.instance
                        .collection('rooms')
                        .doc(widget.roomId)
                        .update({'players.${widget.myPlayerId}.layoutMode': next});
                  },
                  icon: Icon(isTallLayout ? Icons.view_week : Icons.view_column),
                ),
              ],
            ),
            body: Column(
              children: [
                GameHeader(
                    turn: turn, players: players, myId: widget.myPlayerId),
                // ★ 拡大・縮小・スライドを可能にするウィジェット
                Expanded(
                  child: InteractiveViewer(
                  constrained: false,
                  panEnabled: true,
                  boundaryMargin:
                    const EdgeInsets.symmetric(horizontal: 120, vertical: 400), // 画面外にどれくらい動かせるか
                    minScale: 0.5, // 最小50%まで縮小
                    maxScale: 3.0, // 最大300%まで拡大
                    child: Padding(
                        padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width - 16,
                      child: GameGrid(
                        cards: data['cards'],
                        myPlayerId: widget.myPlayerId,
                        turn: turn,
                        isTallLayout: isTallLayout,
                        firstSelectedIndex:
                          data['firstSelectedIndex'] ?? -1,
                        highlightedIndices:
                          (data['highlightedIndices'] as List? ?? [])
                            .cast<int>(),
                        tempRevealedIndices: _tempRevealed,
                        selectedForExchange: _selectedIndices,
                        activeEffect: data['activeEffect'],
                        onTap: (i) => _handleTap(i, data)))),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showResult(int win, Map players) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => AlertDialog(
                title: const Text("終了"),
                content: const Text("ゲームが終了しました。"),
                actions: [
                  TextButton(
                      onPressed: () async {
                        await FirestoreService.resetBoardOnly(widget.roomId);
                        if (mounted) Navigator.pop(c);
                      },
                      child: const Text("再戦"))
                ]));
  }
}
