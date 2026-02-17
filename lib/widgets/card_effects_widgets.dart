import 'dart:math';

class GameEffects {
  /// Q: 各行ごとに横に1マスずらす
  static List<dynamic> applyQueenEffect(
      List<dynamic> cards, int crossAxisCount) {
    List<dynamic> updatedCards = List.from(cards);
    int totalCards = updatedCards.length;
    int rowCount = (totalCards / crossAxisCount).ceil();
    for (int r = 0; r < rowCount; r++) {
      int startIdx = r * crossAxisCount;
      int endIdx = (r + 1) * crossAxisCount;
      if (endIdx > totalCards) endIdx = totalCards;
      if (startIdx >= totalCards) break;
      List<dynamic> row = updatedCards.sublist(startIdx, endIdx);
      if (row.length > 1) {
        var last = row.removeLast();
        row.insert(0, last);
        for (int i = 0; i < row.length; i++)
          updatedCards[startIdx + i] = row[i];
      }
    }
    return updatedCards;
  }

  /// J: 全カードを1行分(13枚)下にスライド
  static List<dynamic> applyJackEffect(
      List<dynamic> cards, int crossAxisCount) {
    List<dynamic> updatedCards = List.from(cards);
    if (updatedCards.length <= crossAxisCount) return updatedCards;
    List<dynamic> lastRow =
        updatedCards.sublist(updatedCards.length - crossAxisCount);
    List<dynamic> remaining =
        updatedCards.sublist(0, updatedCards.length - crossAxisCount);
    return [...lastRow, ...remaining];
  }

  /// 10: 裏返しのカードを最大10枚シャッフル
  static List<dynamic> applyTenEffect(List<dynamic> cards) {
    List<dynamic> updatedCards = List.from(cards);
    final random = Random();
    List<int> faceDownIndices = [];
    for (int i = 0; i < updatedCards.length; i++) {
      if (!updatedCards[i]['isTaken'] && !updatedCards[i]['isFaceUp'])
        faceDownIndices.add(i);
    }
    if (faceDownIndices.isEmpty) return updatedCards;
    faceDownIndices.shuffle(random);
    int shuffleCount = min(faceDownIndices.length, 10);
    List<int> targetIndices = faceDownIndices.sublist(0, shuffleCount);
    List<dynamic> targetData =
        targetIndices.map((idx) => updatedCards[idx]).toList();
    targetData.shuffle(random);
    for (int i = 0; i < targetIndices.length; i++)
      updatedCards[targetIndices[i]] = targetData[i];
    return updatedCards;
  }

  /// 9: 4分割対角入れ替え
  static List<dynamic> applyNineEffect(
      List<dynamic> cards, int crossAxisCount) {
    List<dynamic> updatedCards = List.from(cards);
    int totalCards = updatedCards.length;
    int rowCount = totalCards ~/ crossAxisCount;
    int midRow = rowCount ~/ 2;
    int midCol = crossAxisCount ~/ 2;
    List<dynamic> result = List.from(updatedCards);
    for (int i = 0; i < totalCards; i++) {
      int r = i ~/ crossAxisCount;
      int c = i % crossAxisCount;
      int targetRow = (r < midRow) ? r + (rowCount - midRow) : r - midRow;
      int targetCol = (c < midCol) ? c + (crossAxisCount - midCol) : c - midCol;
      int targetIndex = targetRow * crossAxisCount + targetCol;
      if (targetIndex < totalCards) result[targetIndex] = updatedCards[i];
    }
    return result;
  }

  /// 7: 自動で4枚入れ替え
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

  /// ★ 3, 8用: 指定された複数の位置を入れ替える
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

  /// A, 6用: 透視インデックス取得
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
