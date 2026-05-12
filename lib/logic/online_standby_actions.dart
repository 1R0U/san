import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/player_model.dart';
import '../services/firestore_service.dart';

class OnlineStandbyActions {
  static void editName(
    BuildContext context,
    String roomId,
    PlayerModel me,
  ) {
    final controller = TextEditingController(text: me.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('名前変更'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              FirestoreService.updatePlayer(
                roomId,
                PlayerModel(
                  id: me.id,
                  name: controller.text,
                  layoutMode: me.layoutMode,
                  isActive: true,
                  isReady: me.isReady,
                ),
              );
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  static Future<void> toggleCpuSlot(
    String roomId,
    int slot,
    bool enable,
    int defaultLevel,
    int selectedCount,
  ) async {
    if (enable && selectedCount >= 8) return;
    final doc = FirebaseFirestore.instance.collection('rooms').doc(roomId);
    if (enable) {
      await doc.update({
        'cpuSelectedSlots.$slot': true,
        'cpuSlotLevels.$slot': defaultLevel,
        'cpuCount': selectedCount + 1,
      });
      return;
    }

    await doc.update({
      'cpuSelectedSlots.$slot': FieldValue.delete(),
      'cpuCount': selectedCount > 0 ? selectedCount - 1 : 0,
    });
  }

  static void editCpuLevel(
    BuildContext context,
    String roomId,
    int slot,
    int currentLevel,
    int defaultLevel,
  ) {
    int selected = currentLevel;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('CPU $slot の難易度'),
          content: DropdownButton<int>(
            value: selected,
            items: const [
              DropdownMenuItem(value: 1, child: Text('Easy')),
              DropdownMenuItem(value: 2, child: Text('Normal')),
              DropdownMenuItem(value: 3, child: Text('Hard')),
            ],
            onChanged: (v) {
              if (v == null) return;
              setLocal(() => selected = v);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () async {
                final doc = FirebaseFirestore.instance.collection('rooms').doc(roomId);
                await doc.update({'cpuSlotLevels.$slot': selected});
                final snap = await doc.get();
                if (snap.exists) {
                  final players = Map<String, dynamic>.from(snap.data()?['players'] ?? {});
                  final p = players['$slot'] as Map<String, dynamic>?;
                  if (p != null && p['isCPU'] == true) {
                    await doc.update({'players.$slot.cpuLevel': selected});
                  }
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('保存'),
            ),
            TextButton(
              onPressed: () async {
                final doc = FirebaseFirestore.instance.collection('rooms').doc(roomId);
                await doc.update({'cpuSlotLevels.$slot': defaultLevel});
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('デフォルトに戻す'),
            ),
          ],
        ),
      ),
    );
  }
}