import 'package:flutter/material.dart';

class GameHeader extends StatelessWidget {
  final int turn; // ★ 引数名は「turn」
  final Map<String, dynamic> players;
  final int myId;

  const GameHeader(
      {super.key,
      required this.turn,
      required this.players,
      required this.myId});

  @override
  Widget build(BuildContext context) {
    // アクティブなプレイヤーをID順に並べる
    final pList = players.values.where((p) => p['isActive'] == true).toList()
      ..sort((a, b) => a['id'].compareTo(b['id']));

    return Container(
      height: 85,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.black38,
        border: Border(bottom: BorderSide(color: Colors.white12, width: 2)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        // 中央寄せにするための微調整
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: pList.length,
        itemBuilder: (context, index) {
          final p = pList[index];
          final bool isTurn = turn == p['id'];
          final bool isMe = myId == p['id'];

          // 初期の配色：自分は青系、他人は赤系
          final Color themeColor = isMe ? Colors.blue[700]! : Colors.red[700]!;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 110,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: isTurn ? themeColor : themeColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isTurn ? Colors.white : Colors.white24,
                width: isTurn ? 2 : 1,
              ),
              boxShadow: isTurn
                  ? [
                      BoxShadow(
                          color: themeColor.withOpacity(0.5), blurRadius: 8)
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  p['name'],
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: isTurn ? FontWeight.bold : FontWeight.normal),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text("${p['score']} pt",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace' // スコアを少しデジタルっぽく
                        )),
              ],
            ),
          );
        },
      ),
    );
  }
}
