import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: CardSortGame(),
  ));
}

class CardSortGame extends StatefulWidget {
  const CardSortGame({super.key});
  @override
  State<CardSortGame> createState() => _CardSortGameState();
}

class _CardSortGameState extends State<CardSortGame> {
  List<Map<String, dynamic>> poolCards = [];
  Map<int, List<String>> playerCollections = {1: [], 2: []};
  Map<int, String> playerTargets = {1: '', 2: ''};

  int currentPlayer = 1;
  bool isProcessing = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadGame();
  }

  Future<void> loadGame() async {
    try {
      final String response = await rootBundle.loadString('assets/cards.json');
      final data = json.decode(response);
      List<Map<String, dynamic>> tempPool = [];
      List<String> allGenres = [];

      for (var cat in data['categories']) {
        allGenres.add(cat['genre']);
        for (var item in cat['items']) {
          tempPool.add({
            'text': item,
            'genre': cat['genre'],
            'isFaceUp': false,
            'isTaken': false,
          });
        }
      }

      setState(() {
        allGenres.shuffle();
        playerTargets[1] = allGenres[0];
        playerTargets[2] = allGenres[1];
        playerCollections = {1: [], 2: []};
        poolCards = tempPool..shuffle();
        currentPlayer = 1;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("エラー: $e");
    }
  }

  void handleCardTap(int index) async {
    if (isProcessing ||
        poolCards[index]['isFaceUp'] ||
        poolCards[index]['isTaken']) return;

    setState(() {
      poolCards[index]['isFaceUp'] = true;
      isProcessing = true;
    });

    final selectedCard = poolCards[index];
    final String myTarget = playerTargets[currentPlayer]!;

    if (selectedCard['genre'] == myTarget) {
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() {
        selectedCard['isTaken'] = true;
        playerCollections[currentPlayer]!.add(selectedCard['text']);
        isProcessing = false;
      });

      if (playerCollections[currentPlayer]!.length == 5) {
        showWinDialog(currentPlayer);
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 1000));
      setState(() {
        selectedCard['isFaceUp'] = false;
        currentPlayer = currentPlayer == 1 ? 2 : 1;
        isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      body: Column(
        children: [
          // ヘッダーをさらにスリム化
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(child: playerBox(1)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text("VS",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey)),
                ),
                Expanded(child: playerBox(2)),
              ],
            ),
          ),
          // カードグリッドエリア（縦幅を最大化）
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Center(
                child: Container(
                  constraints:
                      const BoxConstraints(maxWidth: 1000), // 横幅を広げて縦を詰める
                  child: GridView.builder(
                    // スクロールを禁止
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      childAspectRatio: 2.2, // 横：縦の比率。数字を大きくするほど縦が薄くなる
                    ),
                    itemCount: poolCards.length,
                    itemBuilder: (context, index) {
                      final card = poolCards[index];
                      return Opacity(
                        opacity: card['isTaken'] ? 0.0 : 1.0,
                        child: GestureDetector(
                          onTap: () =>
                              card['isTaken'] ? null : handleCardTap(index),
                          child: CardView(
                            text: card['text'],
                            isFaceUp: card['isFaceUp'],
                            backColor: currentPlayer == 1
                                ? Colors.blue[400]!
                                : Colors.red[400]!,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget playerBox(int pNum) {
    bool isTurn = currentPlayer == pNum;
    Color color = pNum == 1 ? Colors.blue : Colors.red;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: isTurn ? color.withOpacity(0.1) : Colors.white,
        border: Border.all(color: isTurn ? color : Colors.grey[300]!, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("P$pNum: ${playerTargets[pNum]}",
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          Text("${playerCollections[pNum]!.length} / 5",
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void showWinDialog(int winner) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text('🎉 プレイヤー$winnerの勝利！'),
        content: Text('「${playerTargets[winner]}」をコンプリート！'),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                loadGame();
              },
              child: const Text('リプレイ')),
        ],
      ),
    );
  }
}

class CardView extends StatelessWidget {
  final String text;
  final bool isFaceUp;
  final Color backColor;

  const CardView(
      {super.key,
      required this.text,
      required this.isFaceUp,
      required this.backColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isFaceUp ? Colors.white : backColor,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 1, offset: Offset(1, 1))
        ],
      ),
      child: Text(
        isFaceUp ? text : "?",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isFaceUp ? Colors.black87 : Colors.white,
        ),
      ),
    );
  }
}
