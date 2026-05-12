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
                  "   A:ランダムなカード８枚の数字を少しの間確認できる\n"
                  "   2:相手のポイントを２ポイント奪う\n"
                  "   3:任意のカードを７枚ずっと表にできる（相手には見えない）\n"
                  "   4:任意の３枚のカードの数字を少しの間確認できる\n"
                  "   5:ランダムなカード３枚の数字を少しの間確認できる\n"
                  "   6:任意のカードを３枚ずっと表にできる（相手には見えない）\n"
                  "   7:任意のカード２枚の場所を入れ替えられる\n"
                  "   8:すべてのカードを逆順に並べ替える\n"
                  "   9:未取得のカードをランダムにシャッフルする\n"
                  "   10:すべてのカードを縦方向に１つスライドさせる\n"
                  "   J:すべてのカードを横方向に１つスライドさせる\n"
                  "   Q:効果なし\n\n"
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
