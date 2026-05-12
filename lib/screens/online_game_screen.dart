import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../logic/cpu_manager.dart';
import '../logic/game_flow_utils.dart';
import '../effects/effect_dialogs.dart';
import '../effects/game_effects_logic.dart';
import '../widgets/online_game_view.dart';
import '../services/firestore_service.dart';
import 'Standby_screen.dart';

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
  bool _isEffectShowing = false;
  bool _isCpuTurnRunning = false;
  bool _isFinalizingGame = false;
  bool _isEndingFlow = false;
  Timestamp? _lastProcessedTimestamp;
  final Map<int, Map<int, String>> _cpuMemory = {};

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

  Future<void> _rollbackCpuSelection(
      DocumentReference<Map<String, dynamic>> docRef, List<dynamic> cards,
      {int? firstIndex, int? secondIndex}) async {
    if (firstIndex != null &&
        firstIndex >= 0 &&
        firstIndex < cards.length &&
        cards[firstIndex]['isTaken'] != true) {
      cards[firstIndex]['isFaceUp'] = false;
    }
    if (secondIndex != null &&
        secondIndex >= 0 &&
        secondIndex < cards.length &&
        cards[secondIndex]['isTaken'] != true) {
      cards[secondIndex]['isFaceUp'] = false;
    }
    await docRef.update({
      'cards': cards,
      'firstSelectedIndex': -1,
      'cpuMoveLock': 0,
      'cpuMoveLockAt': null,
    });
  }

  Future<void> _continueCpuTurnIfNeeded() async {
    if (!mounted || _isEffectShowing || _isCpuTurnRunning || _isEndingFlow) {
      return;
    }

    final snap = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .get();
    if (!snap.exists) return;

    final latest = snap.data() as Map<String, dynamic>;
    if ((latest['winner'] ?? 0) != 0) return;

    final turn = latest['currentTurn'] ?? 1;
    if (turn == widget.myPlayerId) return;

    final players = Map<String, dynamic>.from(latest['players'] ?? {});
    final p = players[turn.toString()] as Map<String, dynamic>?;
    if (p == null || p['isCPU'] != true) return;

    await _handleCpuTurn(latest);
  }

  Future<void> _waitUntilRoomBackToStandby() async {
    for (var i = 0; i < 30; i++) {
      final snap = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .get();
      if (!snap.exists) return;
      final d = snap.data() as Map<String, dynamic>;
      final started = d['isStarted'] == true;
      final winner = (d['winner'] ?? 0) as int;
      if (!started && winner == 0) return;
      await Future.delayed(const Duration(milliseconds: 250));
    }
  }

  Future<void> _handleGameEndFlowIfNeeded(Map<String, dynamic> data) async {
    if (_isEndingFlow) return;
    final winnerId = (data['winner'] ?? 0) as int;
    if (winnerId <= 0) return;

    _isEndingFlow = true;
    try {
      final players = Map<String, dynamic>.from(data['players'] ?? {});
      final ranking = players.entries.where((e) {
        final p = e.value as Map<String, dynamic>;
        return p['isActive'] == true;
      }).map((e) {
        final p = e.value as Map<String, dynamic>;
        return {
          'id': int.tryParse(e.key) ?? 0,
          'name': (p['name'] ?? 'Player ${e.key}').toString(),
          'score': (p['score'] ?? 0) as int,
        };
      }).toList();

      ranking.sort((a, b) {
        final bs = b['score'] as int;
        final as = a['score'] as int;
        if (bs != as) return bs.compareTo(as);
        return (a['id'] as int).compareTo(b['id'] as int);
      });

      final showTop3 = ranking.length >= 3;
      final winnerName = ranking.isNotEmpty
          ? ranking.first['name'].toString()
          : 'Player $winnerId';
      final winnerScore =
          ranking.isNotEmpty ? ranking.first['score'] as int : 0;

      if (mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (c) => AlertDialog(
            title: const Text('ゲーム終了'),
            content: showTop3
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < 3 && i < ranking.length; i++)
                        Text(
                            '${i + 1}位: ${ranking[i]['name']}  ${ranking[i]['score']}点'),
                    ],
                  )
                : Text('勝者: $winnerName  ${winnerScore}点'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }

      if (widget.myPlayerId == 1) {
        await FirestoreService.resetBoardOnly(widget.roomId);
      }
      await _waitUntilRoomBackToStandby();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StandbyScreen(
              roomId: widget.roomId, myPlayerId: widget.myPlayerId),
        ),
      );
    } finally {
      _isEndingFlow = false;
    }
  }

  Future<void> _finalizeGameIfNeeded(Map<String, dynamic> data) async {
    if (_isFinalizingGame) return;
    if ((data['winner'] ?? 0) != 0) return;

    final cards = List<dynamic>.from(data['cards'] ?? []);
    final allTaken =
        cards.isNotEmpty && cards.every((c) => c['isTaken'] == true);
    final firstSelectedIndex = (data['firstSelectedIndex'] ?? -1) as int;
    final noLegalMove = !GameFlowUtils.hasLegalMove(cards, firstSelectedIndex);
    final overTurn = (data['turnCount'] ?? 1) >= 50;

    if (!allTaken && !noLegalMove && !overTurn) return;

    _isFinalizingGame = true;
    try {
      final players = Map<String, dynamic>.from(data['players'] ?? {});
      final winner = GameFlowUtils.resolveWinnerByScore(players);
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .update({
        'winner': winner,
        'turnCount': overTurn ? 50 : (data['turnCount'] ?? 1),
        'firstSelectedIndex': -1,
        'cpuMoveLock': 0,
        'cpuMoveLockAt': null,
      });
    } finally {
      _isFinalizingGame = false;
    }
  }

  Future<void> _handleCpuTurn(Map<String, dynamic> data) async {
    if (_isEffectShowing || _isCpuTurnRunning || _isEndingFlow) return;

    _isCpuTurnRunning = true;
    bool claimed = false;

    try {
      final currentTurn = data['currentTurn'] ?? 1;
      if (currentTurn == widget.myPlayerId) return;
      if ((data['winner'] ?? 0) != 0) return;

      final players = Map<String, dynamic>.from(data['players'] ?? {});
      final currentPlayer =
          players[currentTurn.toString()] as Map<String, dynamic>?;
      if (currentPlayer == null || currentPlayer['isCPU'] != true) return;

      claimed = await FirestoreService.claimCpuMove(widget.roomId, currentTurn);
      if (!claimed) return;

      await Future.delayed(const Duration(milliseconds: 700));

      final freshSnap = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .get();
      if (!freshSnap.exists) return;
      final freshData = freshSnap.data() as Map<String, dynamic>;
      CpuManager.updateCpuMemoryFromData(freshData, _cpuMemory);
      if ((freshData['winner'] ?? 0) != 0) return;
      if ((freshData['currentTurn'] ?? 1) != currentTurn) return;

        if (!GameFlowUtils.hasLegalMove(List<dynamic>.from(freshData['cards'] ?? []),
          (freshData['firstSelectedIndex'] ?? -1) as int)) {
        await _finalizeGameIfNeeded(freshData);
        return;
      }

      final cards = List<dynamic>.from(freshData['cards'] ?? []);
      final freshPlayers =
          Map<String, dynamic>.from(freshData['players'] ?? {});
      final cpuPlayer =
          freshPlayers[currentTurn.toString()] as Map<String, dynamic>?;
      if (cpuPlayer == null || cpuPlayer['isCPU'] != true) return;

      final level = (cpuPlayer['cpuLevel'] ?? 1) as int;
      final move = CpuManager.pickCpuMove(
        cards,
        level: level,
        cpuId: currentTurn,
        cpuMemory: _cpuMemory,
      );
      if (move.length < 2) return;
      final firstIndex = move[0];
      int secondIndex = move[1];

      final docRef =
          FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);

      cards[firstIndex]['isFaceUp'] = true;
      await docRef.update({
        'cards': cards,
        'firstSelectedIndex': firstIndex,
      });
      await Future.delayed(const Duration(milliseconds: 1200));

      final secondSnap = await docRef.get();
      if (!secondSnap.exists) return;
      final secondData = secondSnap.data() as Map<String, dynamic>;
      if ((secondData['winner'] ?? 0) != 0 ||
          (secondData['currentTurn'] ?? 1) != currentTurn) {
        final rollbackCards = List<dynamic>.from(secondData['cards'] ?? []);
        await _rollbackCpuSelection(docRef, rollbackCards,
            firstIndex: firstIndex);
        return;
      }

      final secondCards = List<dynamic>.from(secondData['cards'] ?? []);
      final canUseFirst = firstIndex >= 0 &&
          firstIndex < secondCards.length &&
          secondCards[firstIndex]['isTaken'] != true &&
          secondCards[firstIndex]['isFaceUp'] == true;
      if (!canUseFirst) {
        await _rollbackCpuSelection(docRef, secondCards,
            firstIndex: firstIndex);
        return;
      }

      final secondAvailable = <int>[];
      for (var i = 0; i < secondCards.length; i++) {
        if (i == firstIndex) continue;
        if (secondCards[i]['isTaken'] == true) continue;
        if (secondCards[i]['isFaceUp'] == true) continue;
        secondAvailable.add(i);
      }
      if (!secondAvailable.contains(secondIndex)) {
        if (secondAvailable.isEmpty) {
          await _rollbackCpuSelection(docRef, secondCards,
              firstIndex: firstIndex);
          return;
        }
        secondAvailable.shuffle();
        secondIndex = secondAvailable.first;
      }

      secondCards[secondIndex]['isFaceUp'] = true;
      await docRef.update({'cards': secondCards});

      await Future.delayed(const Duration(milliseconds: 1300));
      final afterSnap = await docRef.get();
      if (!afterSnap.exists) return;
      final afterData = afterSnap.data() as Map<String, dynamic>;
      if ((afterData['winner'] ?? 0) != 0 ||
          (afterData['currentTurn'] ?? 1) != currentTurn) {
        final rollbackCards = List<dynamic>.from(afterData['cards'] ?? []);
        await _rollbackCpuSelection(
          docRef,
          rollbackCards,
          firstIndex: firstIndex,
          secondIndex: secondIndex,
        );
        return;
      }
      var afterCards = List<dynamic>.from(afterData['cards'] ?? []);
      var afterPlayers = Map<String, dynamic>.from(afterData['players'] ?? {});

      final match =
          afterCards[firstIndex]['rank'] == afterCards[secondIndex]['rank'];
      final r = afterCards[secondIndex]['rank'];
      List<int> highlightedIndices = [];
      String? activeEffect;
      List<int> effectData = [];

      if (match) {
        afterCards[firstIndex]['isTaken'] = true;
        afterCards[secondIndex]['isTaken'] = true;
        afterPlayers[currentTurn.toString()]['score'] =
            (afterPlayers[currentTurn.toString()]['score'] ?? 0) +
                GameEffectsLogic.getCardPoints(r);

        final availableAfterMatch = <int>[];
        for (var i = 0; i < afterCards.length; i++) {
          if (afterCards[i]['isTaken'] == true) continue;
          if (afterCards[i]['isFaceUp'] == true) continue;
          availableAfterMatch.add(i);
        }

        if (r == 'J') {
          afterCards = GameEffectsLogic.applyQueenEffect(afterCards);
        } else if (r == '10') {
          afterCards = GameEffectsLogic.applyJackEffect(afterCards);
        } else if (r == '9') {
          final res = GameEffectsLogic.applyTenEffect(afterCards);
          afterCards = res['cards'];
          highlightedIndices = res['indices'];
        } else if (r == '8') {
          afterCards = GameEffectsLogic.applyNineEffect(afterCards);
          activeEffect = 'nine';
        } else if (r == '2') {
          afterPlayers =
              GameEffectsLogic.applyTwoEffect(afterPlayers, currentTurn);
        } else if (r == '7' && availableAfterMatch.length >= 2) {
          final swapTargets = List<int>.from(availableAfterMatch)..shuffle();
          afterCards = GameEffectsLogic.swapSpecificCards(
              afterCards, swapTargets.take(2).toList());
        } else if (r == '6' && availableAfterMatch.length >= 3) {
          final revealTargets = List<int>.from(availableAfterMatch)..shuffle();
          for (final i in revealTargets.take(3)) {
            final card = Map<String, dynamic>.from(afterCards[i]);
            final viewers = List<int>.from(card['permViewers'] ?? []);
            if (!viewers.contains(currentTurn)) viewers.add(currentTurn);
            card['permViewers'] = viewers;
            afterCards[i] = card;
          }
        } else if (r == '4') {
          effectData = GameEffectsLogic.getRandomRevealIndices(
              afterCards, 3, currentTurn);
        } else if (r == '3' && availableAfterMatch.length >= 7) {
          final revealTargets = List<int>.from(availableAfterMatch)..shuffle();
          for (final i in revealTargets.take(7)) {
            final card = Map<String, dynamic>.from(afterCards[i]);
            final viewers = List<int>.from(card['permViewers'] ?? []);
            if (!viewers.contains(currentTurn)) viewers.add(currentTurn);
            card['permViewers'] = viewers;
            afterCards[i] = card;
          }
        } else if (r == '5' || r == 'A') {
          effectData = GameEffectsLogic.getRandomRevealIndices(
              afterCards, r == 'A' ? 8 : 3, currentTurn);
        }
      } else {
        afterCards[firstIndex]['isFaceUp'] = false;
        afterCards[secondIndex]['isFaceUp'] = false;
      }

      final turnOrder = (afterData['turnOrder'] as List? ?? []).cast<int>();
      final nextTurn = match
          ? currentTurn
          : GameEffectsLogic.getNextTurn(currentTurn, afterPlayers, turnOrder);
      final nextTurnCountRaw = (afterData['turnCount'] ?? 1) + (match ? 0 : 1);
      final nextTurnCount = nextTurnCountRaw > 50 ? 50 : nextTurnCountRaw;
      final winner = afterCards.every((c) => c['isTaken'])
          ? currentTurn
            : (nextTurnCount >= 50
              ? GameFlowUtils.resolveWinnerByScore(afterPlayers)
              : 0);

      await docRef.update({
        'cards': afterCards,
        'players': afterPlayers,
        'latestEffect': match ? r : null,
        'effectTimestamp': match ? FieldValue.serverTimestamp() : null,
        'effectData': effectData,
        'highlightedIndices': highlightedIndices,
        'activeEffect': activeEffect,
        'firstSelectedIndex': -1,
        'currentTurn': nextTurn,
        'turnCount': nextTurnCount,
        'winner': winner,
        'cpuMoveLock': 0,
      });
    } finally {
      if (claimed) {
        await FirestoreService.releaseCpuMove(widget.roomId);
      }
      _isCpuTurnRunning = false;
      unawaited(Future.delayed(
          const Duration(milliseconds: 120), _continueCpuTurnIfNeeded));
    }
  }

  // --- エフェクト演出のトリガー ---
  Future<void> _handleEffectTrigger(
      String effectRank, List<int> effectData, bool isMyTurn) async {
    if (mounted) setState(() => _isEffectShowing = true);
    try {
      if (effectRank == 'Q')
        await showMissEffect(context, isSelf: isMyTurn);
      else if (effectRank == 'J')
        await showHorizShiftEffect(context, isSelf: isMyTurn);
      else if (effectRank == '10')
        await showVertShiftEffect(context, isSelf: isMyTurn);
      else if (effectRank == '9')
        await showShuffleEffect(context, isSelf: isMyTurn);
      else if (effectRank == '8')
        await showFlipEffect(context, isSelf: isMyTurn);
      else if (effectRank == '7')
        await showSwapEffect(context, isSelf: isMyTurn);
      else if (effectRank == '6')
        await showPermReveal3Effect(context, isSelf: isMyTurn);
      else if (effectRank == '5')
        await showRevealEffect(context, '5', 3, isSelf: isMyTurn);
      else if (effectRank == '4')
        await showCheckEffect(context, isSelf: isMyTurn);
      else if (effectRank == '3')
        await showPermanentRevealEffect(context, 7, isSelf: isMyTurn);
      else if (effectRank == '2')
        await showStealTwoEffect(context, isSelf: isMyTurn);
      else if (effectRank == 'A')
        await showRevealEffect(context, 'A', 8, isSelf: isMyTurn);

      if (isMyTurn && (effectRank == 'A' || effectRank == '5')) {
        setState(() => _tempRevealed = effectData);
        Future.delayed(const Duration(seconds: 8), () {
          if (mounted) setState(() => _tempRevealed = []);
        });
      }
    } finally {
      if (mounted) setState(() => _isEffectShowing = false);
      unawaited(Future.delayed(
          const Duration(milliseconds: 120), _continueCpuTurnIfNeeded));
    }
  }

  // --- メインタップ処理 ---
  Future<void> _handleTap(int index, Map<String, dynamic> data) async {
    if (_isEndingFlow) return;
    if ((data['winner'] ?? 0) != 0) return;
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

    if (!GameFlowUtils.hasLegalMove(cards, first)) {
      await _finalizeGameIfNeeded(data);
      if (mounted) setState(() => _isProcessing = false);
      return;
    }

    if (first != -1) {
      final validFirst = first >= 0 &&
          first < cards.length &&
          cards[first]['isTaken'] != true &&
          cards[first]['isFaceUp'] == true;
      if (!validFirst) {
        first = -1;
        await docRef.update({'firstSelectedIndex': -1});
      }
    }

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
          if (r == 'J') {
            cards = GameEffectsLogic.applyQueenEffect(cards);
          } else if (r == '10') {
            cards = GameEffectsLogic.applyJackEffect(cards);
          } else if (r == '9') {
            var res = GameEffectsLogic.applyTenEffect(cards);
            cards = res['cards'];
            hIdx = res['indices'];
          } else if (r == '8') {
            cards = GameEffectsLogic.applyNineEffect(cards);
            activeEffect = 'nine';
          } else if (r == '2') {
            playersMap =
                GameEffectsLogic.applyTwoEffect(playersMap, widget.myPlayerId);
          } else if (r == '5' || r == 'A') {
            eData = GameEffectsLogic.getRandomRevealIndices(
                cards, r == 'A' ? 8 : 3, widget.myPlayerId);
          }

          _checkSpecialActionNeeded(r);
          final turnOrder = (data['turnOrder'] as List? ?? []).cast<int>();
          final nextTurn = match
              ? widget.myPlayerId
              : GameEffectsLogic.getNextTurn(
                  widget.myPlayerId, playersMap, turnOrder);
          final currentTurnCount = (data['turnCount'] ?? 1) as int;
          final winner = cards.every((c) => c['isTaken'])
              ? widget.myPlayerId
              : (currentTurnCount >= 50
                  ? GameFlowUtils.resolveWinnerByScore(playersMap)
                  : 0);
          await docRef.update({
            'cards': cards,
            'players': playersMap,
            'firstSelectedIndex': -1,
            'latestEffect': r,
            'effectTimestamp': FieldValue.serverTimestamp(),
            'effectData': eData,
            'highlightedIndices': hIdx,
            'activeEffect': activeEffect,
            'currentTurn': nextTurn,
            'winner': winner,
          });
        } else {
          cards[first]['isFaceUp'] = cards[index]['isFaceUp'] = false;
          final turnOrder = (data['turnOrder'] as List? ?? []).cast<int>();
          final nextTurn = GameEffectsLogic.getNextTurn(
              widget.myPlayerId, playersMap, turnOrder);
          final nextTurnCountRaw = (data['turnCount'] ?? 1) + 1;
          final nextTurnCount = nextTurnCountRaw > 50 ? 50 : nextTurnCountRaw;
          final winner =
                nextTurnCount >= 50
                  ? GameFlowUtils.resolveWinnerByScore(playersMap)
                  : 0;
          await docRef.update({
            'cards': cards,
            'firstSelectedIndex': -1,
            'currentTurn': nextTurn,
            'turnCount': nextTurnCount,
            'winner': winner,
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
      if (r == '7') {
        _isExchangeMode = true;
        _targetCount = 2;
      } else if (r == '4') {
        _isCheckMode = true;
        _targetCount = 3;
      } else if (r == '6') {
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
      onPopInvoked: (didPop) async {
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _handleGameEndFlowIfNeeded(data);
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _finalizeGameIfNeeded(data);
          });
          CpuManager.updateCpuMemoryFromData(data, _cpuMemory);
          final players = Map<String, dynamic>.from(data['players'] ?? {});
          final me =
              players[widget.myPlayerId.toString()] as Map<String, dynamic>?;
          final isTallLayout = (me?['layoutMode'] ?? 'wide') == 'tall';
          final turnOrder = (data['turnOrder'] as List? ?? []).cast<int>();
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
          if (data['currentTurn'] != widget.myPlayerId) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _handleCpuTurn(data);
            });
          }
          return OnlineGameView(
            roomId: widget.roomId,
            myPlayerId: widget.myPlayerId,
            isTallLayout: isTallLayout,
            isMyTurn: isMyTurn,
            turnCount: (data['turnCount'] ?? 1) as int,
            turn: turn,
            players: players,
            turnOrder: turnOrder,
            cards: data['cards'],
            firstSelectedIndex: data['firstSelectedIndex'] ?? -1,
            highlightedIndices:
                (data['highlightedIndices'] as List? ?? []).cast<int>(),
            tempRevealedIndices: _tempRevealed,
            selectedForExchange: _selectedIndices,
            activeEffect: data['activeEffect'],
            onTap: (i) => _handleTap(i, data),
            onToggleLayout: () async {
              final next = isTallLayout ? 'wide' : 'tall';
              await FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(widget.roomId)
                  .update({'players.${widget.myPlayerId}.layoutMode': next});
            },
            onConfirmExit: () async {
              final exit = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('確認'),
                  content: const Text('退出しますか？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('いいえ'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('はい'),
                    ),
                  ],
                ),
              );
              return exit == true;
            },
            onExit: _backToStandby,
          );
        },
      ),
    );
  }
}
