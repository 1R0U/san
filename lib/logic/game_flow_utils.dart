class GameFlowUtils {
  static int resolveWinnerByScore(Map<String, dynamic> players) {
    final activeEntries = players.entries.where((entry) {
      final player = entry.value as Map<String, dynamic>;
      return player['isActive'] == true;
    }).toList();
    if (activeEntries.isEmpty) return 0;

    activeEntries.sort((a, b) {
      final pa = a.value as Map<String, dynamic>;
      final pb = b.value as Map<String, dynamic>;
      final sa = (pa['score'] ?? 0) as int;
      final sb = (pb['score'] ?? 0) as int;
      if (sb != sa) return sb.compareTo(sa);
      final ia = int.tryParse(a.key) ?? 999;
      final ib = int.tryParse(b.key) ?? 999;
      return ia.compareTo(ib);
    });

    return int.tryParse(activeEntries.first.key) ?? 0;
  }

  static bool hasLegalMove(List<dynamic> cards, int firstSelectedIndex) {
    final hidden = <int>[];
    for (var i = 0; i < cards.length; i++) {
      if (cards[i]['isTaken'] == true) continue;
      if (cards[i]['isFaceUp'] != true) hidden.add(i);
    }

    if (firstSelectedIndex != -1) {
      final validFirst = firstSelectedIndex >= 0 &&
          firstSelectedIndex < cards.length &&
          cards[firstSelectedIndex]['isTaken'] != true &&
          cards[firstSelectedIndex]['isFaceUp'] == true;
      if (!validFirst) return hidden.length >= 2;
      return hidden.any((i) => i != firstSelectedIndex);
    }

    return hidden.length >= 2;
  }

  static List<int> pickAvailableIndices(List<dynamic> cards, int count,
      {int? exclude}) {
    final available = <int>[];
    for (var i = 0; i < cards.length; i++) {
      if (i == exclude) continue;
      if (cards[i]['isTaken'] == true) continue;
      if (cards[i]['isFaceUp'] == true) continue;
      available.add(i);
    }
    if (available.isEmpty) return [];
    available.shuffle();
    return available.take(count).toList();
  }

  static void applyPermanentReveal(
      List<dynamic> cards, int viewerId, List<int> indices) {
    for (final index in indices) {
      final card = Map<String, dynamic>.from(cards[index]);
      final viewers = List<int>.from(card['permViewers'] ?? []);
      if (!viewers.contains(viewerId)) viewers.add(viewerId);
      card['permViewers'] = viewers;
      cards[index] = card;
    }
  }

  static List<int> availableAfterMatch(List<dynamic> cards) {
    final available = <int>[];
    for (var i = 0; i < cards.length; i++) {
      if (cards[i]['isTaken'] == true) continue;
      if (cards[i]['isFaceUp'] == true) continue;
      available.add(i);
    }
    return available;
  }
}
