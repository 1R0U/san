import '../logic/game_effects_logic.dart';

class GameLogicService {
  // 得点計算
  static int getCardPoints(String rank) {
    if (rank == 'A') return 1;
    if (rank == 'J') return 11;
    if (rank == 'Q') return 12;
    if (rank == 'K') return 13;
    return int.tryParse(rank) ?? 0;
  }

  // 次のプレイヤーを計算 (8人対応)
  static int getNextTurn(int currentId, Map<String, dynamic> players) {
    final activeIds = players.values
        .where((p) => p['isActive'] == true)
        .map<int>((p) => p['id'] as int)
        .toList()
      ..sort();
    if (activeIds.isEmpty) return 1;
    final currentIndex = activeIds.indexOf(currentId);
    return activeIds[(currentIndex + 1) % activeIds.length];
  }

  // 特殊効果の判定
  static Map<String, dynamic> applyMatchEffects({
    required String rank,
    required List<dynamic> cards,
    required Map<String, dynamic> players,
    required int myId,
  }) {
    List<dynamic> updatedCards = List.from(cards);
    Map<String, dynamic> updatedPlayers = Map<String, dynamic>.from(players);
    List<int> highlightedIndices = [];
    String? activeEffect, nextAction;
    List<int> effectData = [];

    switch (rank) {
      case 'A':
        effectData =
            GameEffectsLogic.getRandomRevealIndices(updatedCards, 8, myId);
        break;
      case '2':
        final others = updatedPlayers.keys
            .where(
                (k) => k != myId.toString() && updatedPlayers[k]['score'] > 0)
            .toList();
        if (others.isNotEmpty) {
          final target = (others..shuffle()).first;
          updatedPlayers[target]['score'] -= 2;
          if (updatedPlayers[target]['score'] < 0)
            updatedPlayers[target]['score'] = 0;
          updatedPlayers[myId.toString()]['score'] += 2;
        }
        break;
      case '3':
        nextAction = 'PERMANENT_CHECK_7';
        break;
      case '4':
        nextAction = 'CHECK_3';
        break;
      case '6':
        effectData =
            GameEffectsLogic.getRandomRevealIndices(updatedCards, 3, myId);
        break;
      case '7':
        nextAction = 'PERMANENT_CHECK_3';
        break;
      case '8':
        nextAction = 'EXCHANGE_2';
        break;
      case '9':
        updatedCards = GameEffectsLogic.applyNineEffect(updatedCards);
        activeEffect = 'nine';
        break;
      case '10':
        var res = GameEffectsLogic.applyTenEffect(updatedCards);
        updatedCards = res['cards'];
        highlightedIndices = res['indices'];
        break;
      case 'J':
        updatedCards = GameEffectsLogic.applyJackEffect(updatedCards);
        break;
      case 'Q':
        updatedCards = GameEffectsLogic.applyQueenEffect(updatedCards);
        break;
    }

    return {
      'cards': updatedCards,
      'players': updatedPlayers,
      'highlightedIndices': highlightedIndices,
      'activeEffect': activeEffect,
      'effectData': effectData,
      'nextAction': nextAction,
    };
  }
}
