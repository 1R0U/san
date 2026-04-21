import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/player_model.dart';
import 'Standby_screen.dart';
import 'local_standby_screen.dart';

enum LobbyMode { online, local }

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});
  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  LobbyMode _mode = LobbyMode.online;

  void _join() async {
    if (_mode == LobbyMode.local) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const LocalStandbyScreen()));
      return;
    }

    final rid = _controller.text.trim();
    if (rid.isEmpty) return;
    setState(() => _loading = true);

    await FirestoreService.ensureRoomExists(rid);
    final slot = await FirestoreService.getEmptySlot(rid);
    if (slot == null) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("満員です")));
      setState(() => _loading = false);
      return;
    }

    await FirestoreService.updatePlayer(
        rid, PlayerModel(id: slot, name: "プレイヤー$slot", isActive: true));

    if (mounted)
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => StandbyScreen(roomId: rid, myPlayerId: slot)));
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A3D14),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.style, size: 120, color: Colors.white),
            const SizedBox(height: 40),
            const Text("真経衰弱",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2)),
            const SizedBox(height: 24),
            SegmentedButton<LobbyMode>(
              showSelectedIcon: false,
              style: ButtonStyle(
                minimumSize: WidgetStateProperty.all(const Size(340, 58)),
                padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.white;
                  }
                  return Colors.white24;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFF0A3D14);
                  }
                  return Colors.white;
                }),
              ),
              segments: const [
                ButtonSegment(
                  value: LobbyMode.online,
                  label: Text('オンライン', style: TextStyle(fontSize: 16)),
                  icon: Icon(Icons.wifi),
                ),
                ButtonSegment(
                  value: LobbyMode.local,
                  label: Text('ローカル', style: TextStyle(fontSize: 16)),
                  icon: Icon(Icons.group),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (s) {
                setState(() => _mode = s.first);
              },
            ),
            const SizedBox(height: 40),
            if (_mode == LobbyMode.online)
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _controller,
                  textAlign: TextAlign.center,

                // ★ 1. ユーザーが入力する文字の色
                style: const TextStyle(
                  color: Colors.black, // 入力文字を青にする
                  fontWeight: FontWeight.bold, // 太字にするとよりハッキリします
                ),

                // ★ 2. カーソル（点滅する棒）の色
                cursorColor: Colors.blue,

                  decoration: InputDecoration(
                    hintText: "ENTER ROOM ID",

                  // ★ 3. ヒントテキスト（入力前の中身）の色
                  hintStyle: TextStyle(
                    color: Colors.black.withOpacity(0.5), // 入力文字より少し薄くするのが一般的
                  ),

                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(
                          color: Colors.blue, width: 2), // 枠も合わせると綺麗
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : ElevatedButton(
                    onPressed: _join,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0A3D14),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(_mode == LobbyMode.online ? "部屋に入る" : "ローカル待機へ",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
          ],
        ),
      ),
    );
  }
}
