import 'dart:math';

/// ゲーム内の特殊効果（A〜K）の計算ロジックを管理するクラス
class GameEffectsLogic {
  /// 2の効果: 相手のスコアを2ポイント奪う
  static Map<String, dynamic> applyTwoEffect(Map scores, int myPlayerId) {
    Map<String, dynamic> newScores = Map.from(scores);
    String myKey = myPlayerId.toString();
    String opponentKey = (myPlayerId == 1 ? 2 : 1).toString();

    int opponentScore = newScores[opponentKey] ?? 0;
    int stealAmount = opponentScore >= 2 ? 2 : opponentScore;

    newScores[myKey] = (newScores[myKey] ?? 0) + stealAmount;
    newScores[opponentKey] = opponentScore - stealAmount;

    return newScores;
  }

  /// クイーン(Q)の効果: 13枚ごとの行の中でカードを右に1つずらす
  static List<dynamic> applyQueenEffect(List<dynamic> cards) {
    List<dynamic> updatedCards = [];
    int rowSize = 13;

    for (int i = 0; i < cards.length; i += rowSize) {
      int end = (i + rowSize < cards.length) ? i + rowSize : cards.length;
      List<dynamic> row = List.from(cards.sublist(i, end));
      if (row.isNotEmpty) {
        var last = row.removeLast();
        row.insert(0, last);
      }
      updatedCards.addAll(row);
    }
    return updatedCards;
  }

  /// ジャック(J)の効果: 全カードを1行分(13枚)下にスライド
  static List<dynamic> applyJackEffect(List<dynamic> cards) {
    int crossAxisCount = 13;
    List<dynamic> updatedCards = List.from(cards);
    if (updatedCards.length <= crossAxisCount) return updatedCards;

    List<dynamic> lastRow =
        updatedCards.sublist(updatedCards.length - crossAxisCount);
    List<dynamic> remaining =
        updatedCards.sublist(0, updatedCards.length - crossAxisCount);
    return [...lastRow, ...remaining];
  }

  /// 10の効果: 裏返しのカードからランダムに最大10枚を選んでシャッフル
  static Map<String, dynamic> applyTenEffect(List<dynamic> cards) {
    List<dynamic> updatedCards = List.from(cards);
    final random = Random();
    List<int> faceDownIndices = [];
    for (int i = 0; i < updatedCards.length; i++) {
      if (updatedCards[i]['isTaken'] == false &&
          updatedCards[i]['isFaceUp'] == false) {
        faceDownIndices.add(i);
      }
    }
    if (faceDownIndices.isEmpty)
      return {'cards': updatedCards, 'indices': <int>[]};

    faceDownIndices.shuffle(random);
    int shuffleCount = min(faceDownIndices.length, 10);
    List<int> targetIndices = faceDownIndices.sublist(0, shuffleCount);
    List<dynamic> targetData =
        targetIndices.map((idx) => updatedCards[idx]).toList();
    targetData.shuffle(random);

    for (int i = 0; i < targetIndices.length; i++) {
      updatedCards[targetIndices[i]] = targetData[i];
    }
    return {'cards': updatedCards, 'indices': targetIndices};
  }

  /// 9の効果: 「田の字」に4分割し、対角ブロックを入れ替える
  static List<dynamic> applyNineEffect(List<dynamic> cards) {
    int crossAxisCount = 13;
    List<dynamic> updatedCards = List.from(cards);
    int totalCards = updatedCards.length;
    int rowCount = (totalCards / crossAxisCount).ceil();
    int midRow = rowCount ~/ 2;
    int midCol = crossAxisCount ~/ 2;

    List<dynamic> result = List.from(updatedCards);
    for (int i = 0; i < totalCards; i++) {
      int r = i ~/ crossAxisCount;
      int c = i % crossAxisCount;
      int targetRow = (r < midRow) ? r + (rowCount - midRow) : r - midRow;
      int targetCol = (c < midCol) ? c + (crossAxisCount - midCol) : c - midCol;
      int targetIndex = targetRow * crossAxisCount + targetCol;
      if (targetIndex >= 0 && targetIndex < totalCards)
        result[targetIndex] = updatedCards[i];
    }
    return result;
  }

  /// 7の効果: 自動で4枚入れ替え
  static Map<String, dynamic> applySevenEffect(List<dynamic> cards) {
    List<dynamic> updatedCards = List.from(cards);
    final random = Random();
    List<int> availableIndices = [];
    for (int i = 0; i < updatedCards.length; i++)
      if (!updatedCards[i]['isTaken']) availableIndices.add(i);
    if (availableIndices.length < 2)
      return {'cards': updatedCards, 'targetIndices': []};

    availableIndices.shuffle(random);
    int count = min(availableIndices.length, 4);
    List<int> targetIndices = availableIndices.sublist(0, count);
    List<dynamic> targetData =
        targetIndices.map((idx) => updatedCards[idx]).toList();
    List<dynamic> shuffledData = List.from(targetData)..shuffle(random);
    for (int i = 0; i < targetIndices.length; i++)
      updatedCards[targetIndices[i]] = shuffledData[i];
    return {'cards': updatedCards, 'targetIndices': targetIndices};
  }

  /// 3, 8, 4用: 指定位置を交換
  static List<dynamic> swapSpecificCards(
      List<dynamic> cards, List<int> indices) {
    List<dynamic> updatedCards = List.from(cards);
    if (indices.length < 2) return updatedCards;
    var firstData = updatedCards[indices[0]];
    for (int i = 0; i < indices.length - 1; i++)
      updatedCards[indices[i]] = updatedCards[indices[i + 1]];
    updatedCards[indices.last] = firstData;
    return updatedCards;
  }

  /// A, 6用: ランダム抽出
  static List<int> getRandomRevealIndices(List<dynamic> cards, int count) {
    List<int> availableIndices = [];
    for (int i = 0; i < cards.length; i++) {
      if (!cards[i]['isTaken'] && !cards[i]['isFaceUp'])
        availableIndices.add(i);
    }
    availableIndices.shuffle();
    return availableIndices.take(count).toList();
  }
}
