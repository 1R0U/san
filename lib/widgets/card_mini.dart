import 'package:flutter/material.dart';

class CardMini extends StatelessWidget {
  final Map card;
  final bool isMyTurn;
  final Color pColor;
  final bool isHighlighted; // ★追加：ハイライトするかどうか
  // ★ 7の特殊効果などで使用するハイライト色を追加
  final Color? highlightColor;

  const CardMini({
    super.key,
    required this.card,
    required this.isMyTurn,
    required this.pColor,
    this.isHighlighted = false, // デフォルトはfalse
    this.highlightColor, // ★ コンストラクタに追加
  });

  @override
  Widget build(BuildContext context) {
    if (card['isTaken']) return const SizedBox.shrink();

    bool isFaceUp = card['isFaceUp'];
    String suit = card['suit'];
    String rank = card['rank'];
    bool isRed = (suit == '♥' || suit == '♦');

    return AnimatedContainer(
      // ContainerをAnimatedContainerに変更（色が滑らかに変わる）
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isFaceUp ? Colors.white : pColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(4),
        border: isHighlighted
            ? Border.all(color: Colors.yellowAccent, width: 4) // ★ハイライト時は太い黄色枠
            : (isFaceUp ? Border.all(color: Colors.grey, width: 1) : null),
        boxShadow: isHighlighted
            ? [
                const BoxShadow(color: Colors.yellow, blurRadius: 10)
              ] // ★光るエフェクト
            : [],
        borderRadius: BorderRadius.circular(2),
        // ★ ハイライトがある場合は指定色で太い枠線を、ない場合は通常の枠線を表示
        border: highlightColor != null
            ? Border.all(color: highlightColor!, width: 2.5)
            : (isFaceUp ? Border.all(color: Colors.grey, width: 1) : null),
        // ★ ハイライト時にカードを光らせる（外光エフェクト）
        boxShadow: highlightColor != null
            ? [
                BoxShadow(
                  color: highlightColor!.withOpacity(0.6),
                  blurRadius: 6,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: Center(
        child: isFaceUp
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(suit,
                      style: TextStyle(
                          fontSize: 10,
                          color: isRed ? Colors.red : Colors.black)),
                  Text(rank,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isRed ? Colors.red : Colors.black,
                          height: 1)),
                ],
              )
            : Icon(
                Icons.help_outline,
                size: 12,
                // ★ ハイライト中はアイコンの色を明るくして目立たせる
                color: highlightColor != null ? Colors.white : Colors.white24,
              ),
      ),
    );
  }
}
