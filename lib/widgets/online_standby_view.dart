import 'package:flutter/material.dart';

import '../models/player_model.dart';
import '../screens/rule_screen.dart';
import 'standby_player_card.dart';

class OnlineStandbyView extends StatelessWidget {
  final String roomId;
  final int myPlayerId;
  final PlayerModel meData;
  final Map<String, dynamic> playersMap;
  final List<Map<String, dynamic>> activeHumans;
  final List<Map<String, dynamic>> activeCpus;
  final Set<int> selectedCpuSlots;
  final int selectedCpuCount;
  final int cpuLevel;
  final Map<String, dynamic> cpuSlotLevels;
  final bool allReady;
  final Set<int> previewCpuSlots;
  final VoidCallback onBack;
  final VoidCallback onToggleReady;
  final Future<void> Function() onStart;
  final void Function(int slot) onEditName;
  final Future<void> Function(int slot, bool enable, int defaultLevel, int selectedCount) onToggleCpuSlot;
  final void Function(int slot, int currentLevel, int defaultLevel) onEditCpuLevel;

  const OnlineStandbyView({
    super.key,
    required this.roomId,
    required this.myPlayerId,
    required this.meData,
    required this.playersMap,
    required this.activeHumans,
    required this.activeCpus,
    required this.selectedCpuSlots,
    required this.selectedCpuCount,
    required this.cpuLevel,
    required this.cpuSlotLevels,
    required this.allReady,
    required this.previewCpuSlots,
    required this.onBack,
    required this.onToggleReady,
    required this.onStart,
    required this.onEditName,
    required this.onToggleCpuSlot,
    required this.onEditCpuLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A3D14),
      appBar: AppBar(
        title: Text('Room: $roomId'),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        actions: [
          IconButton(
            tooltip: 'ルール説明',
            icon: const Icon(Icons.help_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RuleScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.8,
              ),
              itemCount: 8,
              itemBuilder: (context, i) {
                final slot = i + 1;
                final current = playersMap[slot.toString()];
                final isPreviewCpu = previewCpuSlots.contains(slot) &&
                    (current == null || current['isActive'] != true);
                final p = isPreviewCpu
                    ? {
                        'name': 'CPU $slot (予定)',
                        'isReady': false,
                        'isActive': true,
                        'isCPU': true,
                        'cpuLevel': (cpuSlotLevels['$slot'] ?? cpuLevel),
                      }
                    : current;
                final isCpuCard = p?['isCPU'] == true;
                final isEmptySlot = current == null || current['isActive'] != true;
                final canAddCpu = myPlayerId == 1 &&
                    isEmptySlot &&
                    !isCpuCard &&
                    selectedCpuCount < 8;
                final canRemoveCpu =
                    myPlayerId == 1 && isCpuCard && myPlayerId != slot;
                final cardCpuLevel = (p?['cpuLevel'] ??
                    cpuSlotLevels['$slot'] ??
                    cpuLevel) as int;

                return StandbyPlayerCard(
                  label: p?['name'] ?? '空き',
                  isReady: p?['isReady'] ?? false,
                  isJoined: p?['isActive'] ?? false,
                  isCpu: isCpuCard,
                  cpuLevel: cardCpuLevel,
                  isMe: myPlayerId == slot,
                  isAddableEmpty: canAddCpu,
                  onAddCpu: canAddCpu
                      ? () => onToggleCpuSlot(slot, true, cpuLevel, selectedCpuCount)
                      : null,
                  onRemoveCpu: canRemoveCpu
                      ? () => onToggleCpuSlot(slot, false, cpuLevel, selectedCpuCount)
                      : null,
                  onCpuConfig: (myPlayerId == 1 && isCpuCard)
                      ? () => onEditCpuLevel(slot, cardCpuLevel, cpuLevel)
                      : null,
                  onEdit: myPlayerId == slot ? () => onEditName(slot) : null,
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black26,
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '👤 人間: ${activeHumans.length}人',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  '🤖 CPU: ${myPlayerId == 1 ? selectedCpuCount : activeCpus.length}人 / 8人',
                  style: const TextStyle(color: Colors.orangeAccent),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                if (myPlayerId == 1)
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '空き枠の「＋」でCPU追加（最大8人） / CPUの「−」で削除',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        meData.isReady ? Colors.orange : Colors.green,
                  ),
                  onPressed: onToggleReady,
                  child: Text(meData.isReady ? '解除' : '準備OK'),
                ),
                if (myPlayerId == 1 && allReady)
                  TextButton(
                    onPressed: onStart,
                    child: const Text(
                      '開始！',
                      style: TextStyle(
                        color: Colors.yellow,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}