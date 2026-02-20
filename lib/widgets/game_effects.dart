// game_effects.dart
import 'package:flutter/material.dart';

// 共通の演出ダイアログを表示する関数
Future<void> _showEffectDialog(
  BuildContext context, {
  required String label,
  required String rank,
  required IconData icon,
  required String description,
  required Color color,
}) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      // 4秒後に自動で閉じる
      Future.delayed(const Duration(seconds: 4), () {
        if (context.mounted) Navigator.of(context).pop();
      });

      return Material(
        type: MaterialType.transparency,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 140,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: color, width: 6), // 枠線を指定色に
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black87, blurRadius: 30, spreadRadius: 5)
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(rank,
                          style: TextStyle(
                              fontSize: 60,
                              fontWeight: FontWeight.bold,
                              color: color)),
                      const SizedBox(height: 10),
                      Icon(icon, size: 50, color: color),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: color, // タイトルも指定色に合わせる
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: const [
                        Shadow(blurRadius: 10, color: Colors.black)
                      ])),
              const SizedBox(height: 10),
              Text(description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    },
  );
}

// --- 以下、各カードのエフェクト (isSelf引数を追加して分岐) ---

/// Q: 横移動
Future<void> showQueenEffect(BuildContext context,
    {required bool isSelf}) async {
  await _showEffectDialog(
    context,
    label: "QUEEN EFFECT!",
    rank: "Q",
    icon: Icons.sync_alt,
    description: isSelf ? "全体が右にズレた!" : "全体が右にズレた!",
    color: Colors.red,
  );
}

/// J: 縦移動（スライドダウン）
Future<void> showJackEffect(BuildContext context,
    {required bool isSelf}) async {
  await _showEffectDialog(
    context,
    label: "JACK EFFECT!",
    rank: "J",
    icon: Icons.vertical_align_bottom,
    description: isSelf ? "全体が下にズレた!" : "全体が下にズレた!",
    color: Colors.blue,
  );
}

/// 10: シャッフル
Future<void> showTenEffect(BuildContext context, {required bool isSelf}) async {
  await _showEffectDialog(
    context,
    label: "TEN CHAOS!",
    rank: "10",
    icon: Icons.shuffle,
    description: isSelf ? "10枚のカードがシャッフルされた!" : "相手がカードを10枚\nシャッフルした！",
    color: Colors.green,
  );
}

/// 9: クロス入替
Future<void> showNineEffect(BuildContext context,
    {required bool isSelf}) async {
  await _showEffectDialog(
    context,
    label: "NINE CROSS!",
    rank: "9",
    icon: Icons.grid_goldenratio,
    description: isSelf ? "エリアが入れ替わった!" : "相手がエリアを\n入れ替えた！",
    color: Colors.purple,
  );
}

/// 8: 2枚交換
Future<void> showExchangeEightEffect(BuildContext context,
    {required bool isSelf}) async {
  await _showEffectDialog(
    context,
    label: "EXCHANGE MODE",
    rank: "8",
    icon: Icons.published_with_changes,
    description: isSelf ? "カードを2枚指名して\n中身を入れ替える！" : "相手がカードを\n2枚入れ替えた！",
    color: Colors.orange,
  );
}

/// 7: 永久透視（小）
Future<void> showSevenEffect(BuildContext context,
    {required bool isSelf}) async {
  await _showEffectDialog(
    context,
    label: "PERMANENT (Weak)",
    rank: "7",
    icon: Icons.visibility_outlined,
    description: isSelf ? "選んだ 3枚 の中身を\nずっと見れる！" : "相手がカードを 3枚 \n永久透視した！",
    color: Colors.teal,
  );
}

/// 4: 確認モード（3枚）
Future<void> showCheckEffect(BuildContext context,
    {required bool isSelf}) async {
  await _showEffectDialog(
    context,
    label: "CHECK MODE",
    rank: "4",
    icon: Icons.visibility,
    description: isSelf ? "好きなカードを3枚選んで\n少しの間透視できる！" : "相手がカードを\n3枚透視した！",
    color: Colors.cyan,
  );
}

/// 3: 永久透視（7枚選択）
Future<void> showPermanentRevealEffect(BuildContext context, int count,
    {required bool isSelf}) async {
  await _showEffectDialog(
    context,
    label: "PERMANENT VISION",
    rank: "3",
    icon: Icons.fact_check,
    description:
        isSelf ? "好きなカード $count枚 を\nずっと見れる！" : "相手がカードを $count枚 \n永久透視した！",
    color: Colors.indigoAccent,
  );
}

/// 2: ポイント強奪
Future<void> showStealTwoEffect(BuildContext context,
    {required bool isSelf}) async {
  await _showEffectDialog(
    context,
    label: "POINT STEAL",
    rank: "2",
    icon: Icons.back_hand,
    description: isSelf ? "相手から 4pt を\n奪い取った！" : "相手に 4pt \n奪われた！",
    color: Colors.lime,
  );
}

/// A, 6: 一時透視（汎用）
Future<void> showRevealEffect(BuildContext context, String rank, int count,
    {required bool isSelf}) async {
  await _showEffectDialog(
    context,
    label: "REVEAL EFFECT",
    rank: rank,
    icon: Icons.auto_awesome,
    description: isSelf
        ? "ランダムに $count枚 の中身が\n一時的に見えるようになった！"
        : "相手がランダムに $count枚 \n透視した！",
    color: Colors.pinkAccent,
  );
}
