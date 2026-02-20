// rule_screen.dart
import 'package:flutter/material.dart';

class RuleScreen extends StatelessWidget {
  const RuleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A3D14), // ロビーと同じ背景色
      appBar: AppBar(
        title: const Text("ルール説明"),
        backgroundColor: Colors.green[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "真・神経衰弱 ルール",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Divider(),
                SizedBox(height: 10),
                Text(
                  "1. 基本ルール\n"
                  "   通常の神経衰弱と同じく、ペアを揃えていきます。\n"
                  "   そろえたカードの数字が得点となります。\n\n"
                  "2. 特殊効果\n"
                  "   特定のカードを揃えると特殊効果が発動します。\n"
                  "   A:ランダムなカード８枚の数字を確認できる\n"
                  "   2:相手のポイントを２ポイント奪う\n"
                  "   3:任意のカードを７枚ずっと表にできる。*ただし相手には見えない\n"
                  "   4:3枚任意のカードの数字を少しの間確認できる\n"
                  "   5:効果なし\n"
                  "   6:ランダムなカード３枚の数字を少しの間確認できる\n"
                  "   7:任意のカードを３枚ずっと表にできる。*ただし相手には見えない\n"
                  "   8:任意のカード２枚の場所を入れ替えれる\n"
                  "   9:4ブロックに分けて対角のブロックを入れ替える。\n"
                  "   10:ランダムなカードを10枚入れ替える*ただしどちらも見えない\n"
                  "   11:すべてのカードを縦方向にスライドさせる\n"
                  "   12:すべてのカードを横方向にスライドさせる\n"
                  "   13:シンプルに高ポイント\n\n"
                  "3. 勝利条件\n"
                  "   最終的にスコアが高い方の勝ちです。",
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
