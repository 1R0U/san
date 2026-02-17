import 'dart:math';

/// ゲーム内の特殊効果（Q, J, 10, 9など）の計算ロジックを管理するクラス
class GameEffectsLogic {
  /// クイーン(Q)の効果:
  /// 13枚ごとの行の中で、カードを右に1つずらす（次の行にはみ出さない）
  static List<dynamic> applyQueenEffect(List<dynamic> cards) {
    List<dynamic> updatedCards = [];
    int rowSize = 13; // 1行のカード枚数

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

  /// ジャック(J)の効果:
  /// 全カードを1行分(13枚)下にスライドさせる
  // ★修正: 引数から crossAxisCount を削除
  static List<dynamic> applyJackEffect(List<dynamic> cards) {
    int crossAxisCount = 13; // ★ここで固定

    List<dynamic> updatedCards = List.from(cards);
    if (updatedCards.length <= crossAxisCount) return updatedCards;

    // 最後の1行分（後ろから13枚）を切り取る
    List<dynamic> lastRow =
        updatedCards.sublist(updatedCards.length - crossAxisCount);
    // 残りの部分を切り取る
    List<dynamic> remaining =
        updatedCards.sublist(0, updatedCards.length - crossAxisCount);

    // [最後の一行] + [残りの部分] の順で結合
    return [...lastRow, ...remaining];
  }

  /// 10の効果:
  /// 裏返しのカードからランダムに最大10枚を選んでシャッフル
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

    if (faceDownIndices.isEmpty) {
      return {'cards': updatedCards, 'indices': <int>[]};
    }

    faceDownIndices.shuffle(random);
    int shuffleCount = min(faceDownIndices.length, 10);
    List<int> targetIndices = faceDownIndices.sublist(0, shuffleCount);

    List<dynamic> targetData =
        targetIndices.map((idx) => updatedCards[idx]).toList();
    targetData.shuffle(random);

    for (int i = 0; i < targetIndices.length; i++) {
      updatedCards[targetIndices[i]] = targetData[i];
    }

    return {
      'cards': updatedCards,
      'indices': targetIndices,
    };
  }

  /// 9の効果:
  /// 画面を「田の字」に4分割し、対角線上のブロックを入れ替える
  // ★修正: 引数から crossAxisCount を削除
  static List<dynamic> applyNineEffect(List<dynamic> cards) {
    int crossAxisCount = 13; // ★ここで固定

    List<dynamic> updatedCards = List.from(cards);
    int totalCards = updatedCards.length;
    int rowCount = (totalCards / crossAxisCount).ceil();

    int midRow = rowCount ~/ 2;
    int midCol = crossAxisCount ~/ 2;

    List<dynamic> result = List.from(updatedCards);

    for (int i = 0; i < totalCards; i++) {
      int r = i ~/ crossAxisCount;
      int c = i % crossAxisCount;

      int targetRow = r;
      int targetCol = c;

      if (r < midRow) {
        targetRow = r + (rowCount - midRow);
      } else {
        targetRow = r - midRow;
      }

      if (c < midCol) {
        targetCol = c + (crossAxisCount - midCol);
      } else {
        targetCol = c - midCol;
      }

      int targetIndex = targetRow * crossAxisCount + targetCol;

      if (targetIndex >= 0 && targetIndex < totalCards) {
        result[targetIndex] = updatedCards[i];
      }
    }
    return result;
  }
}
