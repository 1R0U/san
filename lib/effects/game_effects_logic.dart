class GameEffectsLogic {
  static int getCardPoints(String rank) {
    if (rank == 'A') return 1;
    if (rank == 'J') return 11;
    if (rank == 'Q') return 12;
    return int.tryParse(rank) ?? 0;
  }

  static int getNextTurn(
      int currentId, Map<String, dynamic> players, List<int>? turnOrder) {
    if (turnOrder != null && turnOrder.isNotEmpty) {
      final activeSet = players.values
          .where((p) => p['isActive'] == true)
          .map<int>((p) => p['id'] as int)
          .toSet();
      final orderedActive = turnOrder.where(activeSet.contains).toList();
      if (orderedActive.isNotEmpty) {
        final idx = orderedActive.indexOf(currentId);
        if (idx >= 0) {
          return orderedActive[(idx + 1) % orderedActive.length];
        }
        return orderedActive.first;
      }
    }

    final activeIds = players.values
        .where((p) => p['isActive'] == true)
        .map<int>((p) => p['id'] as int)
        .toList()
      ..sort();
    if (activeIds.isEmpty) return 1;
    return activeIds[(activeIds.indexOf(currentId) + 1) % activeIds.length];
  }

  static Map<String, dynamic> applyTwoEffect(
      Map<String, dynamic> players, int myId) {
    Map<String, dynamic> newPlayers = Map.from(players);
    String myK = myId.toString();
    List<String> others = newPlayers.keys
        .where((k) => k != myK && (newPlayers[k]['score'] ?? 0) > 0)
        .toList();
    if (others.isNotEmpty) {
      String targetK = (others..shuffle()).first;
      int amount = newPlayers[targetK]['score'] >= 2
          ? 2
          : newPlayers[targetK]['score'] as int;
      newPlayers[myK]['score'] += amount;
      newPlayers[targetK]['score'] -= amount;
    }
    return newPlayers;
  }

  static List<dynamic> applyQueenEffect(List<dynamic> cards) {
    List<dynamic> updated = [];
    for (int i = 0; i < cards.length; i += 12) {
      List<dynamic> row = List.from(cards.sublist(i, i + 12));
      row.insert(0, row.removeLast());
      updated.addAll(row);
    }
    return updated;
  }

  static List<dynamic> applyJackEffect(List<dynamic> cards) {
    return [
      ...cards.sublist(cards.length - 12),
      ...cards.sublist(0, cards.length - 12)
    ];
  }

  static Map<String, dynamic> applyTenEffect(List<dynamic> cards) {
    List<dynamic> updated = List.from(cards);
    List<int> targets = [];
    for (int i = 0; i < updated.length; i++) {
      if (!updated[i]['isTaken'] && !updated[i]['isFaceUp']) targets.add(i);
    }
    if (targets.isEmpty) return {'cards': updated, 'indices': []};
    List<int> shuffleIdx = (targets..shuffle()).take(10).toList();
    List<dynamic> data = shuffleIdx.map((idx) => updated[idx]).toList()
      ..shuffle();
    for (int i = 0; i < shuffleIdx.length; i++) {
      updated[shuffleIdx[i]] = data[i];
    }
    return {'cards': updated, 'indices': shuffleIdx};
  }

  static List<dynamic> applyNineEffect(List<dynamic> cards) =>
      List.from(cards.reversed);

  static List<dynamic> swapSpecificCards(
      List<dynamic> cards, List<int> indices) {
    List<dynamic> updated = List.from(cards);
    if (indices.length < 2) return updated;
    var first = updated[indices[0]];
    for (int i = 0; i < indices.length - 1; i++) {
      updated[indices[i]] = updated[indices[i + 1]];
    }
    updated[indices.last] = first;
    return updated;
  }

  static List<int> getRandomRevealIndices(
      List<dynamic> cards, int count, int myId) {
    List<int> avail = [];
    for (int i = 0; i < cards.length; i++) {
      if (!cards[i]['isTaken'] && !cards[i]['isFaceUp']) avail.add(i);
    }
    return (avail..shuffle()).take(count).toList();
  }
}
