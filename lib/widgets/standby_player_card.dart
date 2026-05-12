import 'package:flutter/material.dart';

class StandbyPlayerCard extends StatelessWidget {
  final String label;
  final bool isReady;
  final bool isJoined;
  final bool isMe;
  final bool isCpu;
  final int? cpuLevel;
  final VoidCallback? onCpuConfig;
  final bool isAddableEmpty;
  final VoidCallback? onAddCpu;
  final VoidCallback? onRemoveCpu;
  final bool showMeLabel;
  final VoidCallback? onEdit; // ★名前変更ダイアログを出すためのコールバック

  const StandbyPlayerCard({
    super.key,
    required this.label,
    required this.isReady,
    required this.isJoined,
    required this.isMe,
    this.isCpu = false,
    this.cpuLevel,
    this.onCpuConfig,
    this.isAddableEmpty = false,
    this.onAddCpu,
    this.onRemoveCpu,
    this.showMeLabel = true,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final canAddCpu = !isJoined && isAddableEmpty && onAddCpu != null;
    return Column(
      children: [
        Stack(
          children: [
            if (canAddCpu)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.18),
                  border: Border.all(color: Colors.greenAccent, width: 2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, size: 34, color: Colors.white),
              )
            else
              Icon(isCpu ? Icons.smart_toy : Icons.account_circle,
                  size: 60,
                  color: isCpu
                      ? Colors.orangeAccent
                      : isMe
                          ? Colors.blueAccent
                          : (isJoined ? Colors.white : Colors.white24)),
            if (isMe)
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Colors.blueAccent, shape: BoxShape.circle),
                    child:
                        const Icon(Icons.edit, size: 12, color: Colors.white),
                  ),
                ),
              ),
            if (isCpu)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'CPU',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            if (isCpu && onRemoveCpu != null)
              Positioned(
                left: 0,
                top: 0,
                child: GestureDetector(
                  onTap: onRemoveCpu,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                        color: Colors.redAccent, shape: BoxShape.circle),
                    child:
                        const Icon(Icons.remove, size: 12, color: Colors.white),
                  ),
                ),
              ),
            if (canAddCpu)
              Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  onTap: onAddCpu,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                        color: Colors.green, shape: BoxShape.circle),
                    child: const Icon(Icons.add, size: 12, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: canAddCpu
              ? onAddCpu
              : isCpu
                  ? onCpuConfig
                  : (isMe ? onEdit : null), // CPUは難易度設定、人間は名前編集
          child: SizedBox(
            width: 100,
            child: Text(
              canAddCpu
                  ? '＋ CPU追加'
                  : isMe
                    ? showMeLabel
                      ? "$label (あなた)"
                      : label
                      : (isCpu ? "$label [CPU]" : label),
              style: TextStyle(
                color: isCpu
                    ? Colors.orangeAccent
                    : (isMe ? Colors.blueAccent : Colors.white),
                fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
                decoration: isMe
                    ? TextDecoration.underline
                    : TextDecoration.none, // 自分の名前はリンク風に
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (isCpu)
          GestureDetector(
            onTap: onCpuConfig,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                border: Border.all(color: Colors.amber),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Lv.${cpuLevel ?? 1} 変更',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        if (isCpu) const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
              color: isReady
                  ? (isCpu ? Colors.deepOrange : Colors.orange)
                  : Colors.black26,
              borderRadius: BorderRadius.circular(10)),
          child: Text(
              isReady
                  ? (isCpu ? "CPU READY" : "READY")
                  : (isJoined ? "WAITING" : "EMPTY"),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
