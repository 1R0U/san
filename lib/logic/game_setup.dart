class GameSetup {
  static List<Map<String, dynamic>> createDeck({
    required List<String> suits,
    required List<String> ranks,
  }) {
    final cards = <Map<String, dynamic>>[];
    for (final suit in suits) {
      for (final rank in ranks) {
        cards.add({
          'rank': rank,
          'suit': suit,
          'isFaceUp': false,
          'isTaken': false,
          'permViewers': <int>[],
        });
      }
    }
    cards.shuffle();
    return cards;
  }

  static Map<String, Map<String, dynamic>> createPlayers(
    List<Map<String, dynamic>> sourcePlayers,
  ) {
    final players = <String, Map<String, dynamic>>{};
    for (final player in sourcePlayers) {
      final id = player['id'] as int;
      players['$id'] = {
        'id': id,
        'name': player['name'] as String,
        'score': 0,
        'isActive': true,
        'isCPU': player['isCPU'] == true,
        'cpuLevel': (player['cpuLevel'] ?? 2) as int,
      };
    }
    return players;
  }

  static List<int> createTurnOrder(List<Map<String, dynamic>> sourcePlayers) {
    final order = sourcePlayers.map((p) => p['id'] as int).toList()..shuffle();
    return order;
  }
}
