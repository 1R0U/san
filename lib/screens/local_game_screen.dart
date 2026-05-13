import 'dart:async';
import 'package:flutter/material.dart';
import '../logic/cpu_manager.dart';
import '../logic/game_setup.dart';
import '../logic/local_game_flow.dart';
import '../effects/effect_dialogs.dart';
import '../effects/game_effects_logic.dart';
import '../widgets/local_game_view.dart';

class LocalGameScreen extends StatefulWidget {
  final List<Map<String, dynamic>> players;
  final int cardCount;
  final int maxTurns;

  const LocalGameScreen({super.key, required this.players, this.cardCount = 48, this.maxTurns = 50});

  @override
  State<LocalGameScreen> createState() => _LocalGameScreenState();
}

class _LocalGameScreenState extends State<LocalGameScreen> {
  late List<dynamic> _cards;
  late Map<String, dynamic> _players;
  late List<int> _turnOrder;
  int _turn = 1;
  int _turnCount = 1;
  int _winner = 0;
  int _firstSelectedIndex = -1;
  bool _isProcessing = false;
  bool _cpuTurnScheduled = false;
  bool _isExchangeMode = false;
  bool _isCheckMode = false;
  bool _isPermanentCheckMode = false;
  bool _isTallLayout = false;
  int _targetCount = 0;
  List<int> _selectedIndices = [];
  List<int> _tempRevealed = [];
  String? _activeEffect;
  List<int> _highlightedIndices = [];
  final Map<int, Map<int, String>> _cpuMemory = {};

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    const ranks = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q'];

    _cards = GameSetup.createDeck(
      suits: GameSetup.suitsForCount(widget.cardCount),
      ranks: ranks,
    );
    _players = GameSetup.createPlayers(widget.players);
    _turnOrder = GameSetup.createTurnOrder(widget.players);
    _turn = _turnOrder.first;
    _turnCount = 1;
    _winner = 0;
    _firstSelectedIndex = -1;
    _isProcessing = false;
    _cpuTurnScheduled = false;
    _isExchangeMode = false;
    _isCheckMode = false;
    _isPermanentCheckMode = false;
    _targetCount = 0;
    _selectedIndices = [];
    _tempRevealed = [];
    _activeEffect = null;
    _highlightedIndices = [];
    _cpuMemory.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleCpuTurn());
  }

  Map<String, dynamic>? get _currentPlayer =>
      _players['$_turn'] as Map<String, dynamic>?;

  bool get _isCurrentTurnCpu => _currentPlayer?['isCPU'] == true;

  void _finalizeGameIfNeeded() {
    if (_winner != 0) return;

    final allTaken = _cards.isNotEmpty && _cards.every((card) => card['isTaken'] == true);
    final noLegalMove = !CpuManager.hasLegalMove(_cards, _firstSelectedIndex);
    final overTurn = widget.maxTurns > 0 && _turnCount >= widget.maxTurns;

    if (!allTaken && !noLegalMove && !overTurn) return;

    _winner = CpuManager.resolveWinnerByScore(_players);
    if (mounted) {
      setState(() {});
      _showResult();
    }
  }

  Future<void> _handleEffectTrigger(
      String effectRank, List<int> effectData, bool isMyTurn) async {
    if (mounted) setState(() => _isProcessing = true);
    try {
      if (effectRank == 'Q') {
        await showMissEffect(context, isSelf: isMyTurn);
      } else if (effectRank == 'J') {
        await showHorizShiftEffect(context, isSelf: isMyTurn);
      } else if (effectRank == '10') {
        await showVertShiftEffect(context, isSelf: isMyTurn);
      } else if (effectRank == '9') {
        await showShuffleEffect(context, isSelf: isMyTurn);
      } else if (effectRank == '8') {
        await showFlipEffect(context, isSelf: isMyTurn);
      } else if (effectRank == '7') {
        await showSwapEffect(context, isSelf: isMyTurn);
      } else if (effectRank == '6') {
        await showPermReveal3Effect(context, isSelf: isMyTurn);
      } else if (effectRank == '5') {
        await showRevealEffect(context, '5', 3, isSelf: isMyTurn);
      } else if (effectRank == '4') {
        await showCheckEffect(context, isSelf: isMyTurn);
      } else if (effectRank == '3') {
        await showPermanentRevealEffect(context, 7, isSelf: isMyTurn);
      } else if (effectRank == '2') {
        await showStealTwoEffect(context, isSelf: isMyTurn);
      } else if (effectRank == 'A') {
        await showRevealEffect(context, 'A', 8, isSelf: isMyTurn);
      }

      if (effectRank == 'A' || effectRank == '5') {
        setState(() => _tempRevealed = effectData);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _tempRevealed = []);
        });
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _scheduleCpuTurn() {
    if (!mounted || _cpuTurnScheduled || _isProcessing || _winner != 0) return;
    if (!_isCurrentTurnCpu) return;
    _cpuTurnScheduled = true;
    Future.delayed(Duration.zero, () {
      _cpuTurnScheduled = false;
      if (mounted) {
        unawaited(_runCpuTurn());
      }
    });
  }

  Future<void> _runCpuTurn() async {
    if (!mounted || _isProcessing || !_isCurrentTurnCpu || _winner != 0) return;

    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 700));

    CpuManager.updateCpuMemoryFromData({'cards': _cards, 'players': _players}, _cpuMemory);
    final level = (_currentPlayer?['cpuLevel'] ?? 2) as int;
    final move = CpuManager.pickCpuMove(
      _cards,
      level: level,
      cpuId: _turn,
      cpuMemory: _cpuMemory,
    );

    if (move.length < 2) {
      if (mounted) setState(() => _isProcessing = false);
      _finalizeGameIfNeeded();
      return;
    }

    final firstIndex = move[0];
    final secondIndex = move[1];

    if (!mounted) return;
    setState(() {
      _cards[firstIndex]['isFaceUp'] = true;
      _firstSelectedIndex = firstIndex;
    });

    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() {
      _cards[secondIndex]['isFaceUp'] = true;
    });

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    await _resolvePair(isCpuTurn: true, firstIndex: firstIndex, secondIndex: secondIndex);
    if (mounted) {
      setState(() => _isProcessing = false);
      if (_winner == 0) _scheduleCpuTurn();
    }
  }

  Future<void> _resolvePair({
    required bool isCpuTurn,
    required int firstIndex,
    required int secondIndex,
  }) async {
    final currentTurn = _turn;
    final rank = _cards[secondIndex]['rank'] as String;
    final result = LocalGameFlow.resolvePair(
      cards: _cards,
      players: _players,
      turnOrder: _turnOrder,
      currentTurn: currentTurn,
      turnCount: _turnCount,
      isCpuTurn: isCpuTurn,
      firstIndex: firstIndex,
      secondIndex: secondIndex,
      maxTurns: widget.maxTurns,
    );

    _cards = result.cards;
    _players = result.players;
    _turn = result.nextTurn;
    _turnCount = result.nextTurnCount;
    _highlightedIndices = result.highlightedIndices;
    _activeEffect = result.activeEffect;
    _tempRevealed = result.tempRevealed;
    _isExchangeMode = result.isExchangeMode;
    _isCheckMode = result.isCheckMode;
    _isPermanentCheckMode = result.isPermanentCheckMode;
    _targetCount = result.targetCount;
    _selectedIndices = result.selectedIndices;

    if (rank == 'Q' || rank == 'J' || rank == '10' || rank == '9' ||
        rank == '8' || rank == '7' || rank == '6' || rank == '5' || rank == '4' ||
        rank == '3' || rank == '2' || rank == 'A') {
      final effectData = (rank == 'A')
          ? List<int>.from(CpuManager.pickAvailableIndices(_cards, 8))
          : (rank == '5')
              ? List<int>.from(CpuManager.pickAvailableIndices(_cards, 3))
              : <int>[];
      await _handleEffectTrigger(rank, effectData, !isCpuTurn);
    }

    _firstSelectedIndex = -1;
    if (mounted) setState(() {});

    if (_winner != 0 && mounted) {
      _showResult();
      return;
    }
  }

  Future<void> _handleTap(int index) async {
    if (_winner != 0 || _isProcessing || _tempRevealed.isNotEmpty) return;
    if (!CpuManager.hasLegalMove(_cards, _firstSelectedIndex)) {
      _finalizeGameIfNeeded();
      return;
    }
    if (_isExchangeMode || _isCheckMode || _isPermanentCheckMode) {
      _handleSpecialModeSelection(index);
      return;
    }
    if (_isCurrentTurnCpu) return;
    if (_cards[index]['isFaceUp'] == true || _cards[index]['isTaken'] == true) return;

    if (_firstSelectedIndex == -1) {
      setState(() {
        _cards[index]['isFaceUp'] = true;
        _firstSelectedIndex = index;
      });
      return;
    }

    if (_firstSelectedIndex >= 0 &&
        (_firstSelectedIndex >= _cards.length ||
            _cards[_firstSelectedIndex]['isTaken'] == true ||
            _cards[_firstSelectedIndex]['isFaceUp'] != true)) {
      setState(() => _firstSelectedIndex = -1);
      return;
    }

    setState(() {
      _isProcessing = true;
      _cards[index]['isFaceUp'] = true;
    });

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    await _resolvePair(isCpuTurn: false, firstIndex: _firstSelectedIndex, secondIndex: index);
    if (mounted) {
      setState(() => _isProcessing = false);
      if (_winner == 0) _scheduleCpuTurn();
    }
  }

  void _handleSpecialModeSelection(int index) {
    if (_selectedIndices.contains(index) || _cards[index]['isFaceUp'] == true) return;
    setState(() => _selectedIndices.add(index));

    if (_selectedIndices.length >= _targetCount) {
      if (_isCheckMode) {
        _tempRevealed = List<int>.from(_selectedIndices);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _tempRevealed = []);
        });
      } else if (_isPermanentCheckMode) {
        CpuManager.applyPermanentReveal(_cards, _turn, _selectedIndices);
      } else if (_isExchangeMode) {
        _cards = GameEffectsLogic.swapSpecificCards(_cards, _selectedIndices);
      }

      setState(() {
        _isCheckMode = false;
        _isPermanentCheckMode = false;
        _isExchangeMode = false;
        _selectedIndices = [];
      });
    }
  }

  void _showResult() {
    final ranking = _players.values.toList()
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
            children: ranking
                .map((player) => ListTile(
                      dense: true,
                      title: Text(player['name']),
                      trailing: Text('${player['score']} pt'),
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
            onPressed: () {
              Navigator.pop(c);
              Navigator.pop(context);
            },
            child: const Text('待機へ'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmExit() async {
    final exit = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('確認'),
        content: const Text('待機画面に戻りますか？'),
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
  }

  void _exitToLobby() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return LocalGameView(
      isTallLayout: _isTallLayout,
      turn: _turn,
      turnCount: _turnCount,
      maxTurns: widget.maxTurns,
      players: _players,
      turnOrder: _turnOrder,
      cards: _cards,
      firstSelectedIndex: _firstSelectedIndex,
      highlightedIndices: _highlightedIndices,
      tempRevealedIndices: _tempRevealed,
      selectedForExchange: _selectedIndices,
      activeEffect: _activeEffect,
      onTap: _handleTap,
      onToggleLayout: () => setState(() => _isTallLayout = !_isTallLayout),
      onConfirmExit: _confirmExit,
      onExit: _exitToLobby,
    );
  }
}
