class GameEffectsLogic {
  // Q: 横に1つずつずらす
  static List<dynamic> applyQueenEffect(List<dynamic> cards) {
    List<dynamic> newCards = List.from(cards);
    for (int i = 0; i < 4; i++) {
      int start = i * 13;
      var last = newCards[start + 12];
      for (int j = 12; j > 0; j--) {
        newCards[start + j] = newCards[start + j - 1];
      }
      newCards[start] = last;
    }
    return newCards;
  }

  // J: 縦に1つずつずらす
  static List<dynamic> applyJackEffect(List<dynamic> cards) {
    List<dynamic> newCards = List.from(cards);
    for (int col = 0; col < 13; col++) {
      var last = newCards[39 + col];
      for (int row = 3; row > 0; row--) {
        newCards[row * 13 + col] = newCards[(row - 1) * 13 + col];
      }
      newCards[col] = last;
    }
    return newCards;
  }

  // 10: シャッフル (取られていないカードのみ)
  static Map<String, dynamic> applyTenEffect(List<dynamic> cards) {
    List<dynamic> newCards = List.from(cards);
    List<int> availableIndices = [];
    for (int i = 0; i < newCards.length; i++) {
      if (!newCards[i]['isTaken']) availableIndices.add(i);
    }
    List<dynamic> targetCards =
        availableIndices.map((i) => newCards[i]).toList();
    targetCards.shuffle();
    for (int i = 0; i < availableIndices.length; i++) {
      newCards[availableIndices[i]] = targetCards[i];
    }
    return {'cards': newCards, 'indices': availableIndices};
  }

  // 9: 全体を反転（エリア交換の簡易版）
  static List<dynamic> applyNineEffect(List<dynamic> cards) =>
      List.from(cards.reversed);

  // 6 or A: 透視インデックス取得
  static List<int> getRandomRevealIndices(
      List<dynamic> cards, int count, int myId) {
    List<int> available = [];
    for (int i = 0; i < cards.length; i++) {
      if (!cards[i]['isTaken'] && !cards[i]['isFaceUp']) available.add(i);
    }
    return (available..shuffle()).take(count).toList();
  }

  // 8: 指定した2枚を入れ替える
  static List<dynamic> swapSpecificCards(
      List<dynamic> cards, List<int> indices) {
    if (indices.length < 2) return cards;
    List<dynamic> newCards = List.from(cards);
    var temp = newCards[indices[0]];
    newCards[indices[0]] = newCards[indices[1]];
    newCards[indices[1]] = temp;
    return newCards;
  }
}
