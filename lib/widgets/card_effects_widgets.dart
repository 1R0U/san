import 'dart:math';

/// ゲーム内の特殊効果（10, J, Qが揃った時）を管理するクラス
class GameEffects {
  /// クイーン(Q)が揃った時: カード全体を後ろに1マスずらす
  /// 一番最後のカードが一番最初(0番目)に来ます
  static List<dynamic> applyQueenEffect(List<dynamic> cards) {
    List<dynamic> updatedCards = List.from(cards);
    if (updatedCards.isNotEmpty) {
      var last = updatedCards.removeLast();
      updatedCards.insert(0, last);
    }
    return updatedCards;
  }

  /// ジャック(J)が揃った時: 全カードを1行分(13枚)下にスライドさせる
  /// 一番下の行が一番上に移動します
  static List<dynamic> applyJackEffect(
      List<dynamic> cards, int crossAxisCount) {
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

  /// 10が揃った時: 裏返しのカードからランダムに最大10枚を選んでシャッフル
  static List<dynamic> applyTenEffect(List<dynamic> cards) {
    List<dynamic> updatedCards = List.from(cards);
    final random = Random();

    // まだ取られておらず(isTaken:false)、表になっていない(isFaceUp:false)カードのINDEXを抽出
    List<int> faceDownIndices = [];
    for (int i = 0; i < updatedCards.length; i++) {
      if (!updatedCards[i]['isTaken'] && !updatedCards[i]['isFaceUp']) {
        faceDownIndices.add(i);
      }
    }

    if (faceDownIndices.isEmpty) return updatedCards;

    // シャッフル対象のINDEXを決定（最大10枚）
    faceDownIndices.shuffle(random);
    int shuffleCount = min(faceDownIndices.length, 10);
    List<int> targetIndices = faceDownIndices.sublist(0, shuffleCount);

    // 対象カードのデータ（rank/suit等）を抽出
    List<dynamic> targetData =
        targetIndices.map((idx) => updatedCards[idx]).toList();

    // データの中身だけをシャッフル
    targetData.shuffle(random);

    // 元のインデックス位置にシャッフルしたデータを書き戻す
    for (int i = 0; i < targetIndices.length; i++) {
      updatedCards[targetIndices[i]] = targetData[i];
    }

    return updatedCards;
  }

  /// 9が揃った時: 画面を「田の字」に4分割し、対角線上のブロックを入れ替える
  static List<dynamic> applyNineEffect(
      List<dynamic> cards, int crossAxisCount) {
    List<dynamic> updatedCards = List.from(cards);
    int totalCards = updatedCards.length;
    int rowCount = totalCards ~/ crossAxisCount; // 行数（例: 4行）

    int midRow = rowCount ~/ 2; // 中間の行
    int midCol = crossAxisCount ~/ 2; // 中間の列

    // 新しい配置を保持する一時的なリスト
    List<dynamic> result = List.from(updatedCards);

    for (int i = 0; i < totalCards; i++) {
      int r = i ~/ crossAxisCount; // 現在の行
      int c = i % crossAxisCount; // 現在の列

      int targetRow;
      int targetCol;

      // --- 入れ替えロジック ---
      // 左上(r < midRow, c < midCol) <-> 右下(r >= midRow, c >= midCol)
      // 右上(r < midRow, c >= midCol) <-> 左下(r >= midRow, c < midCol)

      if (r < midRow) {
        targetRow = r + (rowCount - midRow); // 下側へ
      } else {
        targetRow = r - midRow; // 上側へ
      }

      if (c < midCol) {
        targetCol = c + (crossAxisCount - midCol); // 右側へ
      } else {
        targetCol = c - midCol; // 左側へ
      }

      // 範囲外エラー防止（念のため）
      int targetIndex = targetRow * crossAxisCount + targetCol;
      if (targetIndex < totalCards) {
        result[targetIndex] = updatedCards[i];
      }
    }
    return result;
  }
}
