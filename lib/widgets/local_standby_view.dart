import 'package:flutter/material.dart';

import '../screens/rule_screen.dart';
import 'standby_player_card.dart';

class LocalStandbyView extends StatelessWidget {
  final int humanCount;
  final int cpuCount;
  final int totalCount;
  final List<TextEditingController> controllers;
  final Set<int> cpuSlots;
  final Map<int, int> cpuSlotLevels;
  final int cardCount;
  final int maxTurns;
  final ValueChanged<int> onHumanCountChanged;
  final ValueChanged<int> onAddCpu;
  final ValueChanged<int> onRemoveCpu;
  final void Function(int slot) onEditCpuLevel;
  final void Function(int slot) onEditName;
  final ValueChanged<int> onCardCountChanged;
  final ValueChanged<int> onMaxTurnsChanged;
  final VoidCallback onStart;

  const LocalStandbyView({
    super.key,
    required this.humanCount,
    required this.cpuCount,
    required this.totalCount,
    required this.controllers,
    required this.cpuSlots,
    required this.cpuSlotLevels,
    required this.cardCount,
    required this.maxTurns,
    required this.onHumanCountChanged,
    required this.onAddCpu,
    required this.onRemoveCpu,
    required this.onEditCpuLevel,
    required this.onEditName,
    required this.onCardCountChanged,
    required this.onMaxTurnsChanged,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A3D14),
      appBar: AppBar(
        title: const Text('ローカル待機'),
        backgroundColor: Colors.transparent,
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('人間', style: TextStyle(color: Colors.white)),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: humanCount,
                dropdownColor: const Color(0xFF114A1E),
                style: const TextStyle(color: Colors.white),
                items: List.generate(
                  8,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text('${i + 1}人'),
                  ),
                ),
                onChanged: (value) {
                  if (value == null) return;
                  onHumanCountChanged(value);
                },
              ),
              const SizedBox(width: 16),
              Text(
                'CPU: $cpuCount人 / 8人',
                style: const TextStyle(color: Colors.orangeAccent),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('枚数', style: TextStyle(color: Colors.white70)),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: cardCount,
                dropdownColor: const Color(0xFF114A1E),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 24, child: Text('24枚')),
                  DropdownMenuItem(value: 48, child: Text('48枚')),
                  DropdownMenuItem(value: 72, child: Text('72枚')),
                  DropdownMenuItem(value: 96, child: Text('96枚')),
                ],
                onChanged: (v) { if (v != null) onCardCountChanged(v); },
              ),
              const SizedBox(width: 20),
              const Text('ターン', style: TextStyle(color: Colors.white70)),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: maxTurns,
                dropdownColor: const Color(0xFF114A1E),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 50, child: Text('50')),
                  DropdownMenuItem(value: 100, child: Text('100')),
                  DropdownMenuItem(value: 150, child: Text('150')),
                  DropdownMenuItem(value: 200, child: Text('200')),
                  DropdownMenuItem(value: 0, child: Text('∞')),
                ],
                onChanged: (v) { if (v != null) onMaxTurnsChanged(v); },
              ),
            ],
          ),
          const SizedBox(height: 8),
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
              itemBuilder: (context, index) {
                final slot = index + 1;
                final isHuman = slot <= humanCount;
                final isCpu = cpuSlots.contains(slot);
                final isEmpty = !isHuman && !isCpu;
                final canAddCpu = isEmpty && totalCount < 8;
                final cpuLevel = cpuSlotLevels[slot] ?? 2;
                final controller = controllers[slot - 1];
                final label = isHuman
                    ? (controller.text.trim().isEmpty
                        ? 'プレイヤー$slot'
                        : controller.text.trim())
                    : (isCpu ? 'CPU $slot' : '空き');

                return StandbyPlayerCard(
                  label: label,
                  isReady: isHuman || isCpu,
                  isJoined: isHuman || isCpu,
                  isMe: isHuman,
                  showMeLabel: false,
                  isCpu: isCpu,
                  cpuLevel: cpuLevel,
                  onCpuConfig: isCpu ? () => onEditCpuLevel(slot) : null,
                  isAddableEmpty: canAddCpu,
                  onAddCpu: canAddCpu ? () => onAddCpu(slot) : null,
                  onRemoveCpu: isCpu ? () => onRemoveCpu(slot) : null,
                  onEdit: isHuman ? () => onEditName(slot) : null,
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
                  '👤 人間: $humanCount人',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  '🤖 CPU: $cpuCount人 / 8人',
                  style: const TextStyle(color: Colors.orangeAccent),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0A3D14),
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              child: const Text('ローカル対戦を開始'),
            ),
          ),
        ],
      ),
    );
  }
}