import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/player_model.dart';
import 'standby_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});
  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _controller = TextEditingController();
  bool _loading = false;

  void _join() async {
    final rid = _controller.text.trim();
    if (rid.isEmpty) return;
    setState(() => _loading = true);
    final slot = await FirestoreService.getEmptySlot(rid);
    if (slot == null) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("満員です")));
      setState(() => _loading = false);
      return;
    }
    if (slot == 1) await FirestoreService.resetRoomFull8(rid);
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
            const Text("CARD MATCH ONLINE",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2)),
            const SizedBox(height: 40),
            SizedBox(
              width: 280,
              child: TextField(
                controller: _controller,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: "ENTER ROOM ID",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none),
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
                    child: const Text("JOIN GAME",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
          ],
        ),
      ),
    );
  }
}
