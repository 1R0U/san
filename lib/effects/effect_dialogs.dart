import 'package:flutter/material.dart';

Future<void> _showBaseEffect(
  BuildContext context,
  String title,
  String message,
  IconData icon,
  Color color,
) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      Future.delayed(const Duration(seconds: 2), () {
        if (ctx.mounted) Navigator.pop(ctx);
      });
      return AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: color, width: 2),
          borderRadius: BorderRadius.circular(15),
        ),
        title: Icon(icon, color: color, size: 50),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> showHorizShiftEffect(BuildContext context, {required bool isSelf}) =>
    _showBaseEffect(
      context,
      '← Slide',
      isSelf ? '列をスライドさせた！' : '相手が列をスライドさせた！',
      Icons.swap_horiz,
      Colors.pinkAccent,
    );

Future<void> showVertShiftEffect(BuildContext context, {required bool isSelf}) =>
    _showBaseEffect(
      context,
      '↓ Slide',
      isSelf ? '行をスライドさせた！' : '相手が行をスライドさせた！',
      Icons.swap_vert,
      Colors.blueAccent,
    );

Future<void> showShuffleEffect(BuildContext context, {required bool isSelf}) =>
    _showBaseEffect(
      context,
      'Chaos Shuffle',
      '未取得のカードをシャッフル！',
      Icons.shuffle,
      Colors.orangeAccent,
    );

Future<void> showFlipEffect(BuildContext context, {required bool isSelf}) =>
    _showBaseEffect(
      context,
      'Board Flip',
      '盤面を反転させた！',
      Icons.flip,
      Colors.purpleAccent,
    );

Future<void> showSwapEffect(BuildContext context, {required bool isSelf}) =>
    _showBaseEffect(
      context,
      'Card Swap',
      isSelf ? 'カードを2枚選んで入れ替えよう' : '相手が入れ替え中...',
      Icons.multiple_stop,
      Colors.tealAccent,
    );

Future<void> showPermReveal3Effect(BuildContext context, {required bool isSelf}) =>
    _showBaseEffect(
      context,
      'Perm Eye x3',
      isSelf ? 'カードを3枚選んで永久透視！' : '相手が透視中...',
      Icons.visibility,
      Colors.lightGreenAccent,
    );

Future<void> showRevealEffect(BuildContext context, String rank, int count,
        {required bool isSelf}) =>
    _showBaseEffect(
      context,
      '$rank Reveal',
      isSelf ? 'ランダムに$count枚を透視！' : '相手が透視中...',
      Icons.remove_red_eye,
      Colors.yellowAccent,
    );

Future<void> showCheckEffect(BuildContext context, {required bool isSelf}) =>
    _showBaseEffect(
      context,
      'Four Check',
      isSelf ? '3枚選んで一時的に透視！' : '相手が透視中...',
      Icons.search,
      Colors.cyanAccent,
    );

Future<void> showPermanentRevealEffect(BuildContext context, int count,
        {required bool isSelf}) =>
    _showBaseEffect(
      context,
      'Three Legend',
      isSelf ? '7枚選んで永久透視！' : '相手が透視中...',
      Icons.auto_awesome,
      Colors.amberAccent,
    );

Future<void> showStealTwoEffect(BuildContext context, {required bool isSelf}) =>
    _showBaseEffect(
      context,
      'Two Steal',
      isSelf ? '相手から2ポイント奪った！' : 'ポイントを奪われた！',
      Icons.money_off,
      Colors.redAccent,
    );

Future<void> showMissEffect(BuildContext context, {required bool isSelf}) =>
    _showBaseEffect(
      context,
      'Miss',
      isSelf ? 'ハズレだ...' : '相手はハズレだった...',
      Icons.cancel,
      Colors.grey,
    );
