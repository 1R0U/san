import 'package:flutter/material.dart';

// --- 演出用関数（エフェクト表示） ---

Future<void> _showBaseEffect(BuildContext context, String title, String message,
    IconData icon, Color color) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      Future.delayed(const Duration(seconds: 2), () {
        if (ctx.mounted) Navigator.pop(ctx);
      });
      return AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
            side: BorderSide(color: color, width: 2),
            borderRadius: BorderRadius.circular(15)),
        title: Icon(icon, color: color, size: 50),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style: TextStyle(
                    color: color, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      );
    },
  );
}

Future<void> showQueenEffect(BuildContext context, {required bool isSelf}) =>
    _showBaseEffect(
        context,
        "Queen Shift",
        isSelf ? "列をスライドさせた！" : "相手が列をスライドさせた！",
        Icons.swap_horiz,
        Colors.pinkAccent);

Future<void> showJackEffect(BuildContext context, {required bool isSelf}) =>
    _showBaseEffect(
        context,
        "Jack Shift",
        isSelf ? "行をスライドさせた！" : "相手が行をスライドさせた！",
        Icons.swap_vert,
        Colors.blueAccent);

Future<void> showTenEffect(BuildContext context, {required bool isSelf}) =>
    _showBaseEffect(context, "Ten Chaos", "未取得のカードをシャッフル！", Icons.shuffle,
        Colors.orangeAccent);

Future<void> showNineEffect(BuildContext context, {required bool isSelf}) =>
    _showBaseEffect(
        context, "Nine Cross", "盤面を反転させた！", Icons.flip, Colors.purpleAccent);

Future<void> showExchangeEightEffect(BuildContext context,
        {required bool isSelf}) =>
    _showBaseEffect(
        context,
        "Eight Swap",
        isSelf ? "カードを2枚選んで入れ替えよう" : "相手が入れ替え中...",
        Icons.multiple_stop,
        Colors.tealAccent);

Future<void> showSevenEffect(BuildContext context, {required bool isSelf}) =>
    _showBaseEffect(
        context,
        "Seven Eye",
        isSelf ? "カードを3枚選んで永久透視！" : "相手が透視中...",
        Icons.visibility,
        Colors.lightGreenAccent);

Future<void> showRevealEffect(BuildContext context, String rank, int count,
        {required bool isSelf}) =>
    _showBaseEffect(
        context,
        "$rank Reveal",
        isSelf ? "ランダムに$count枚を透視！" : "相手が透視中...",
        Icons.remove_red_eye,
        Colors.yellowAccent);

Future<void> showCheckEffect(BuildContext context, {required bool isSelf}) =>
    _showBaseEffect(context, "Four Check",
        isSelf ? "3枚選んで一時的に透視！" : "相手が透視中...", Icons.search, Colors.cyanAccent);

Future<void> showPermanentRevealEffect(BuildContext context, int count,
        {required bool isSelf}) =>
    _showBaseEffect(
        context,
        "Three Legend",
        isSelf ? "7枚選んで永久透視！" : "相手が透視中...",
        Icons.auto_awesome,
        Colors.amberAccent);

Future<void> showStealTwoEffect(BuildContext context, {required bool isSelf}) =>
    _showBaseEffect(
        context,
        "Two Steal",
        isSelf ? "相手から2ポイント奪った！" : "ポイントを奪われた！",
        Icons.money_off,
        Colors.redAccent);

// --- ロジック用クラス ---

class GameEffectsLogic {
  static int getCardPoints(String rank) {
    if (rank == 'A') return 1;
    if (rank == 'J') return 11;
    if (rank == 'Q') return 12;
    if (rank == 'K') return 13;
    return int.tryParse(rank) ?? 0;
  }

  static int getNextTurn(int currentId, Map<String, dynamic> players) {
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
    for (int i = 0; i < cards.length; i += 13) {
      List<dynamic> row = List.from(cards.sublist(i, i + 13));
      row.insert(0, row.removeLast());
      updated.addAll(row);
    }
    return updated;
  }

  static List<dynamic> applyJackEffect(List<dynamic> cards) {
    return [
      ...cards.sublist(cards.length - 13),
      ...cards.sublist(0, cards.length - 13)
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
    for (int i = 0; i < shuffleIdx.length; i++)
      updated[shuffleIdx[i]] = data[i];
    return {'cards': updated, 'indices': shuffleIdx};
  }

  static List<dynamic> applyNineEffect(List<dynamic> cards) =>
      List.from(cards.reversed);

  static List<dynamic> swapSpecificCards(
      List<dynamic> cards, List<int> indices) {
    List<dynamic> updated = List.from(cards);
    if (indices.length < 2) return updated;
    var first = updated[indices[0]];
    for (int i = 0; i < indices.length - 1; i++)
      updated[indices[i]] = updated[indices[i + 1]];
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
