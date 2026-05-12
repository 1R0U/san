import 'dart:math';

class CpuLogic {
  static int rankWeight(String rank) {
    switch (rank) {
      case 'A':
        return 100;
      case '10':
        return 95;
      case '2':
        return 92;
      case '6':
        return 88;
      case 'Q':
        return 84;
      case 'J':
        return 80;
      case '9':
        return 76;
      case '8':
        return 72;
      case '7':
        return 68;
      case '4':
        return 64;
      case '3':
        return 60;
      case 'K':
        return 56;
      default:
        return int.tryParse(rank) ?? 0;
    }
  }

  static void updateCpuMemoryFromData(
    Map<String, dynamic> data,
    Map<int, Map<int, String>> cpuMemory,
  ) {
    final cards = List<dynamic>.from(data['cards'] ?? []);
    final players = Map<String, dynamic>.from(data['players'] ?? {});

    final cpuIds = <int>[];
    for (final entry in players.entries) {
      final p = entry.value as Map<String, dynamic>;
      if (p['isCPU'] == true) {
        final id = int.tryParse(entry.key);
        if (id != null) cpuIds.add(id);
      }
    }

    for (final cpuId in cpuIds) {
      final memory = cpuMemory.putIfAbsent(cpuId, () => {});

      memory.removeWhere((idx, _) =>
          idx < 0 || idx >= cards.length || cards[idx]['isTaken'] == true);

      for (var i = 0; i < cards.length; i++) {
        final card = cards[i] as Map<String, dynamic>;
        if (card['isTaken'] == true) {
          memory.remove(i);
          continue;
        }
        final permViewers = List<int>.from(card['permViewers'] ?? []);
        final visibleToCpu =
            card['isFaceUp'] == true || permViewers.contains(cpuId);
        if (visibleToCpu) {
          memory[i] = card['rank'] as String;
        }
      }
    }
  }

  static List<int> pickMove(
    List<dynamic> cards, {
    required int level,
    required int cpuId,
    required Map<int, Map<int, String>> cpuMemory,
  }) {
    final available = <int>[];
    final knownByRank = <String, List<int>>{};

    for (var i = 0; i < cards.length; i++) {
      if (cards[i]['isTaken'] == true) continue;
      if (cards[i]['isFaceUp'] == true) continue;
      available.add(i);
    }

    if (available.length < 2) return [];

    final memory = Map<int, String>.from(cpuMemory[cpuId] ?? {});
    memory.removeWhere(
        (idx, _) => idx < 0 || idx >= cards.length || !available.contains(idx));
    for (final entry in memory.entries) {
      knownByRank.putIfAbsent(entry.value, () => []).add(entry.key);
    }

    if (level <= 1) {
      return _randomMove(available);
    }

    final pairEntries = knownByRank.entries
        .where((e) => e.value.length >= 2)
        .toList()
      ..sort((a, b) => rankWeight(b.key).compareTo(rankWeight(a.key)));

    if (level == 2) {
      if (pairEntries.isNotEmpty && Random().nextDouble() < 0.65) {
        final topCount = pairEntries.length >= 3 ? 3 : pairEntries.length;
        final choice = pairEntries[Random().nextInt(topCount)];
        final picks = List<int>.from(choice.value)..shuffle();
        return picks.take(2).toList();
      }
      return _randomMove(available);
    }

    if (pairEntries.isNotEmpty) {
      final best = pairEntries.first;
      final picks = List<int>.from(best.value)..shuffle();
      return picks.take(2).toList();
    }

    final knownSingles = memory.keys.where((i) => available.contains(i)).toList();
    if (knownSingles.isNotEmpty) {
      knownSingles.sort(
          (a, b) => rankWeight(memory[b]!).compareTo(rankWeight(memory[a]!)));
      final first = knownSingles.first;
      final unknown = available.where((i) => !memory.containsKey(i)).toList();
      if (unknown.isNotEmpty) {
        unknown.shuffle();
        return [first, unknown.first];
      }
      final candidates = available.where((i) => i != first).toList();
      if (candidates.isNotEmpty) {
        candidates.shuffle();
        return [first, candidates.first];
      }
    }

    return _randomMove(available);
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

  static List<int> _randomMove(List<int> available) {
    if (available.length < 2) return [];
    final picks = List<int>.from(available)..shuffle();
    return [picks[0], picks[1]];
  }
}