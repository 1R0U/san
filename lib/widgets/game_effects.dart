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
      Future.delayed(const Duration(seconds: 2), () {
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
                  style: const TextStyle(
                      color: Colors.yellowAccent,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 10, color: Colors.black)])),
              const SizedBox(height: 10),
              Text(description,
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

/// Q: 横移動
Future<void> showQueenEffect(BuildContext context) async {
  await _showEffectDialog(
    context,
    label: "QUEEN EFFECT!",
    rank: "Q",
    icon: Icons.sync_alt,
    description: "全体が右にズレた...",
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
    description: "全体が下にズレた...",
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
    description: "10枚のカードがシャッフルされた...",
    color: Colors.green,
  );
}

/// 9: クロス入替
Future<void> showNineEffect(BuildContext context) async {
  await _showEffectDialog(
    context,
    label: "NINE CROSS!",
    rank: "9",
    icon: Icons.grid_goldenratio, // 田の字っぽいアイコン
    description: "エリアが入れ替わった...",
    color: Colors.purple,
  );
}
