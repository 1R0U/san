import 'cpu_manager.dart';
import '../effects/game_effects_logic.dart';

class LocalPairResolution {
  final List<dynamic> cards;
  final Map<String, dynamic> players;
  final int winner;
  final int nextTurn;
  final int nextTurnCount;
  final List<int> highlightedIndices;
  final String? activeEffect;
  final List<int> tempRevealed;
  final bool isExchangeMode;
  final bool isCheckMode;
  final bool isPermanentCheckMode;
  final int targetCount;
  final List<int> selectedIndices;

  const LocalPairResolution({
    required this.cards,
    required this.players,
    required this.winner,
    required this.nextTurn,
    required this.nextTurnCount,
    required this.highlightedIndices,
    required this.activeEffect,
    required this.tempRevealed,
    required this.isExchangeMode,
    required this.isCheckMode,
    required this.isPermanentCheckMode,
    required this.targetCount,
    required this.selectedIndices,
  });
}

class LocalGameFlow {
  static LocalPairResolution resolvePair({
    required List<dynamic> cards,
    required Map<String, dynamic> players,
    required List<int> turnOrder,
    required int currentTurn,
    required int turnCount,
    required bool isCpuTurn,
    required int firstIndex,
    required int secondIndex,
    int maxTurns = 50,
  }) {
    final updatedCards = List<dynamic>.from(cards);
    final updatedPlayers = Map<String, dynamic>.from(players);
    final match = updatedCards[firstIndex]['rank'] == updatedCards[secondIndex]['rank'];
    final rank = updatedCards[secondIndex]['rank'] as String;

    final highlightedIndices = <int>[];
    String? activeEffect;
    final tempRevealed = <int>[];
    bool isExchangeMode = false;
    bool isCheckMode = false;
    bool isPermanentCheckMode = false;
    int targetCount = 0;
    List<int> selectedIndices = [];

    if (match) {
      updatedCards[firstIndex]['isTaken'] = true;
      updatedCards[secondIndex]['isTaken'] = true;
      updatedPlayers['$currentTurn']['score'] =
          (updatedPlayers['$currentTurn']['score'] ?? 0) +
              GameEffectsLogic.getCardPoints(rank);

      if (rank == 'J') {
        return _finish(
          cards: GameEffectsLogic.applyQueenEffect(updatedCards),
          players: updatedPlayers,
          nextTurn: currentTurn,
          turnCount: turnCount,
          winnerOverride: null,
          highlightedIndices: highlightedIndices,
          activeEffect: activeEffect,
          tempRevealed: tempRevealed,
          isExchangeMode: isExchangeMode,
          isCheckMode: isCheckMode,
          isPermanentCheckMode: isPermanentCheckMode,
          targetCount: targetCount,
          selectedIndices: selectedIndices,
        );
      }
      if (rank == '10') {
        return _finish(
          cards: GameEffectsLogic.applyJackEffect(updatedCards),
          players: updatedPlayers,
          nextTurn: currentTurn,
          turnCount: turnCount,
          winnerOverride: null,
          highlightedIndices: highlightedIndices,
          activeEffect: activeEffect,
          tempRevealed: tempRevealed,
          isExchangeMode: isExchangeMode,
          isCheckMode: isCheckMode,
          isPermanentCheckMode: isPermanentCheckMode,
          targetCount: targetCount,
          selectedIndices: selectedIndices,
        );
      }
      if (rank == '9') {
        final result = GameEffectsLogic.applyTenEffect(updatedCards);
        updatedCards
          ..clear()
          ..addAll(result['cards'] as List<dynamic>);
        highlightedIndices.addAll(List<int>.from(result['indices'] ?? []));
      } else if (rank == '8') {
        final swapped = GameEffectsLogic.applyNineEffect(updatedCards);
        updatedCards
          ..clear()
          ..addAll(swapped);
        activeEffect = 'nine';
      } else if (rank == '2') {
        final updated = GameEffectsLogic.applyTwoEffect(updatedPlayers, currentTurn);
        updatedPlayers
          ..clear()
          ..addAll(updated);
      } else if (rank == '7') {
        if (isCpuTurn) {
          final swapTargets = CpuManager.pickAvailableIndices(updatedCards, 2);
          if (swapTargets.length >= 2) {
            final swapped = GameEffectsLogic.swapSpecificCards(updatedCards, swapTargets);
            updatedCards
              ..clear()
              ..addAll(swapped);
          }
        } else {
          isExchangeMode = true;
          targetCount = 2;
        }
      } else if (rank == '6') {
        if (isCpuTurn) {
          CpuManager.applyPermanentReveal(updatedCards, currentTurn,
              CpuManager.pickAvailableIndices(updatedCards, 3));
        } else {
          isPermanentCheckMode = true;
          targetCount = 3;
        }
      } else if (rank == '4') {
        if (isCpuTurn) {
          tempRevealed.addAll(CpuManager.pickAvailableIndices(updatedCards, 3));
        } else {
          isCheckMode = true;
          targetCount = 3;
        }
      } else if (rank == '3') {
        if (isCpuTurn) {
          CpuManager.applyPermanentReveal(updatedCards, currentTurn,
              CpuManager.pickAvailableIndices(updatedCards, 7));
        } else {
          isPermanentCheckMode = true;
          targetCount = 7;
        }
      } else if (rank == '5') {
        tempRevealed.addAll(CpuManager.pickAvailableIndices(updatedCards, 3));
      } else if (rank == 'A') {
        tempRevealed.addAll(CpuManager.pickAvailableIndices(updatedCards, 8));
      }
    } else {
      updatedCards[firstIndex]['isFaceUp'] = false;
      updatedCards[secondIndex]['isFaceUp'] = false;
    }

    final allTaken = updatedCards.every((card) => card['isTaken'] == true);
    final nextTurnCount = match ? turnCount : (maxTurns > 0 ? (turnCount + 1).clamp(0, maxTurns) : turnCount + 1);
    final overTurn = maxTurns > 0 && nextTurnCount >= maxTurns;
    final winner = allTaken
        ? currentTurn
        : (overTurn ? CpuManager.resolveWinnerByScore(updatedPlayers) : 0);
    final nextTurn = match
        ? currentTurn
        : GameEffectsLogic.getNextTurn(currentTurn, updatedPlayers, turnOrder);

    return _finish(
      cards: updatedCards,
      players: updatedPlayers,
      nextTurn: nextTurn,
      turnCount: nextTurnCount,
      winnerOverride: winner,
      highlightedIndices: highlightedIndices,
      activeEffect: activeEffect,
      tempRevealed: tempRevealed,
      isExchangeMode: isExchangeMode,
      isCheckMode: isCheckMode,
      isPermanentCheckMode: isPermanentCheckMode,
      targetCount: targetCount,
      selectedIndices: selectedIndices,
    );
  }

  static LocalPairResolution _finish({
    required List<dynamic> cards,
    required Map<String, dynamic> players,
    required int nextTurn,
    required int turnCount,
    required int? winnerOverride,
    required List<int> highlightedIndices,
    required String? activeEffect,
    required List<int> tempRevealed,
    required bool isExchangeMode,
    required bool isCheckMode,
    required bool isPermanentCheckMode,
    required int targetCount,
    required List<int> selectedIndices,
  }) {
    return LocalPairResolution(
      cards: cards,
      players: players,
      winner: winnerOverride ?? 0,
      nextTurn: nextTurn,
      nextTurnCount: turnCount,
      highlightedIndices: highlightedIndices,
      activeEffect: activeEffect,
      tempRevealed: tempRevealed,
      isExchangeMode: isExchangeMode,
      isCheckMode: isCheckMode,
      isPermanentCheckMode: isPermanentCheckMode,
      targetCount: targetCount,
      selectedIndices: selectedIndices,
    );
  }
}
