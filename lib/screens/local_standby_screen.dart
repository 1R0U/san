import 'package:flutter/material.dart';
import 'local_game_screen.dart';

class LocalStandbyScreen extends StatefulWidget {
  const LocalStandbyScreen({super.key});

  @override
  State<LocalStandbyScreen> createState() => _LocalStandbyScreenState();
}

class _LocalStandbyScreenState extends State<LocalStandbyScreen> {
  int _playerCount = 2;
  final List<TextEditingController> _controllers = List.generate(
    8,
    (i) => TextEditingController(text: 'プレイヤー${i + 1}'),
  );

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _startLocalGame() {
    final names = List.generate(
      _playerCount,
      (i) {
        final v = _controllers[i].text.trim();
        return v.isEmpty ? 'プレイヤー${i + 1}' : v;
      },
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocalGameScreen(playerNames: names),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A3D14),
      appBar: AppBar(
        title: const Text('ローカル待機'),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('人数', style: TextStyle(color: Colors.white)),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: _playerCount,
                  dropdownColor: const Color(0xFF114A1E),
                  style: const TextStyle(color: Colors.white),
                  items: List.generate(
                    7,
                    (i) => DropdownMenuItem(
                      value: i + 2,
                      child: Text('${i + 2}人'),
                    ),
                  ),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _playerCount = v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _playerCount,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: TextField(
                    controller: _controllers[i],
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      labelText: 'プレイヤー${i + 1}名',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _startLocalGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0A3D14),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              child: const Text('ローカル対戦を開始'),
            ),
          ],
        ),
      ),
    );
  }
}
