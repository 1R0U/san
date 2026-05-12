import 'package:flutter/material.dart';

class LocalStandbyActions {
  static void editCpuLevel(
    BuildContext context,
    int slot,
    int currentLevel,
    void Function(int level) onSave,
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
            onChanged: (value) {
              if (value == null) return;
              setLocal(() => selected = value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                onSave(selected);
                Navigator.pop(ctx);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  static void editName(
    BuildContext context,
    int slot,
    TextEditingController controller,
    VoidCallback onSaved,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('プレイヤー$slot の名前'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              onSaved();
              Navigator.pop(ctx);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}