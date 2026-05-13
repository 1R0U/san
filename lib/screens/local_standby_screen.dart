import 'package:flutter/material.dart';
import '../logic/local_standby_actions.dart';
import '../widgets/local_standby_view.dart';
import 'local_game_screen.dart';

class LocalStandbyScreen extends StatefulWidget {
  const LocalStandbyScreen({super.key});

  @override
  State<LocalStandbyScreen> createState() => _LocalStandbyScreenState();
}

class _LocalStandbyScreenState extends State<LocalStandbyScreen> {
  int _humanCount = 1;
  int _cardCount = 48;
  int _maxTurns = 50;
  final Set<int> _cpuSlots = {};
  final Map<int, int> _cpuSlotLevels = {};
  final List<TextEditingController> _controllers = List.generate(
    8,
    (i) => TextEditingController(text: 'プレイヤー${i + 1}'),
  );

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  int get _cpuCount => _cpuSlots.length;
  int get _totalCount => _humanCount + _cpuCount;

  void _setHumanCount(int value) {
    setState(() {
      _humanCount = value;
      _cpuSlots.removeWhere((slot) => slot <= _humanCount);
      _cpuSlotLevels.removeWhere((slot, _) => slot <= _humanCount);
    });
  }

  void _addCpu(int slot) {
    if (_totalCount >= 8) return;
    setState(() {
      _cpuSlots.add(slot);
      _cpuSlotLevels[slot] = _cpuSlotLevels[slot] ?? 2;
    });
  }

  void _removeCpu(int slot) {
    setState(() {
      _cpuSlots.remove(slot);
      _cpuSlotLevels.remove(slot);
    });
  }

  void _editCpuLevel(int slot) {
    LocalStandbyActions.editCpuLevel(
      context,
      slot,
      _cpuSlotLevels[slot] ?? 2,
      (level) => setState(() => _cpuSlotLevels[slot] = level),
    );
  }

  void _editName(int slot) {
    final controller = _controllers[slot - 1];
    LocalStandbyActions.editName(
      context,
      slot,
      controller,
      () => setState(() {}),
    );
  }

  void _startLocalGame() {
    final players = <Map<String, dynamic>>[];

    for (int slot = 1; slot <= _humanCount; slot++) {
      final value = _controllers[slot - 1].text.trim();
      players.add({
        'id': slot,
        'name': value.isEmpty ? 'プレイヤー$slot' : value,
        'isCPU': false,
      });
    }

    final cpuSlots = _cpuSlots.toList()..sort();
    for (final slot in cpuSlots) {
      players.add({
        'id': slot,
        'name': 'CPU $slot',
        'isCPU': true,
        'cpuLevel': _cpuSlotLevels[slot] ?? 2,
      });
    }

    players.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocalGameScreen(
          players: players,
          cardCount: _cardCount,
          maxTurns: _maxTurns,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LocalStandbyView(
      humanCount: _humanCount,
      cpuCount: _cpuCount,
      totalCount: _totalCount,
      controllers: _controllers,
      cpuSlots: _cpuSlots,
      cpuSlotLevels: _cpuSlotLevels,
      cardCount: _cardCount,
      maxTurns: _maxTurns,
      onHumanCountChanged: _setHumanCount,
      onAddCpu: _addCpu,
      onRemoveCpu: _removeCpu,
      onEditCpuLevel: _editCpuLevel,
      onEditName: _editName,
      onCardCountChanged: (v) => setState(() => _cardCount = v),
      onMaxTurnsChanged: (v) => setState(() => _maxTurns = v),
      onStart: _startLocalGame,
    );
  }
}
