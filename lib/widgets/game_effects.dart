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
                  border: Border.all(color: Colors.orangeAccent, width: 6),
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
                  style: const TextStyle(
                      color: Colors.yellowAccent,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 10, color: Colors.black)])),
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

// --- 以下、各カードのエフェクト ---

/// Q: 横移動
Future<void> showQueenEffect(BuildContext context) async {
  await _showEffectDialog(
    context,
    label: "QUEEN EFFECT!",
    rank: "Q",
    icon: Icons.sync_alt,
    description: "全体が右にズレた!",
    color: Colors.red,
  );
}

/// J: 縦移動（スライドダウン）
Future<void> showJackEffect(BuildContext context) async {
  await _showEffectDialog(
    context,
    label: "JACK EFFECT!",
    rank: "J",
    icon: Icons.vertical_align_bottom,
    description: "全体が下にズレた!",
    color: Colors.blue,
  );
}

/// 10: シャッフル
Future<void> showTenEffect(BuildContext context) async {
  await _showEffectDialog(
    context,
    label: "TEN CHAOS!",
    rank: "10",
    icon: Icons.shuffle,
    description: "10枚のカードがシャッフルされた!",
    color: Colors.green,
  );
}

/// 9: クロス入替
Future<void> showNineEffect(BuildContext context) async {
  await _showEffectDialog(
    context,
    label: "NINE CROSS!",
    rank: "9",
    icon: Icons.grid_goldenratio,
    description: "エリアが入れ替わった!",
    color: Colors.purple,
  );
}

/// 8: 2枚交換
Future<void> showExchangeEightEffect(BuildContext context) async {
  await _showEffectDialog(
    context,
    label: "EXCHANGE MODE",
    rank: "8",
    icon: Icons.published_with_changes,
    description: "カードを2枚指名して\n中身を入れ替える！",
    color: Colors.orange,
  );
}

/// 7: 自動シャッフル（4枚）
Future<void> showSevenEffect(BuildContext context) async {
  await _showEffectDialog(
    context,
    label: "SEVEN SWAP",
    rank: "7",
    icon: Icons.autorenew,
    description: "ランダムに4枚の場所が\n入れ替わった！",
    color: Colors.teal,
  );
}

/// 4: 確認モード（3枚）
Future<void> showCheckEffect(BuildContext context) async {
  await _showEffectDialog(
    context,
    label: "CHECK MODE",
    rank: "4",
    icon: Icons.visibility,
    description: "好きなカードを3枚選んで\n中身をこっそり確認！",
    color: Colors.cyan,
  );
}

/// 3: 永久透視（7枚選択）
Future<void> showPermanentRevealEffect(BuildContext context, int count) async {
  await _showEffectDialog(
    context,
    label: "PERMANENT VISION",
    rank: "3",
    icon: Icons.fact_check, // 自分で選ぶアイコン
    description: "好きなカード $count枚 を\nずっと見れるようにする！",
    color: Colors.indigoAccent,
  );
}

/// 2: ポイント強奪
Future<void> showStealTwoEffect(BuildContext context) async {
  await _showEffectDialog(
    context,
    label: "POINT STEAL",
    rank: "2",
    icon: Icons.back_hand,
    description: "相手から 2pt を\n奪い取った！",
    color: Colors.lime,
  );
}

/// A, 6: 一時透視（汎用）
Future<void> showRevealEffect(
    BuildContext context, String rank, int count) async {
  await _showEffectDialog(
    context,
    label: "REVEAL EFFECT",
    rank: rank,
    icon: Icons.auto_awesome,
    description: "ランダムに $count枚 の中身が\n一時的に見えるようになった！",
    color: Colors.pinkAccent,
  );
}
