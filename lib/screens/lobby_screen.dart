import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'standby_screen.dart';
import 'rule_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});
  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final TextEditingController _roomController = TextEditingController();
  bool isLoading = false;

  void _enterRoom() async {
    final roomId = _roomController.text.trim();
    if (roomId.isEmpty) return;
    setState(() => isLoading = true);

    try {
      final docRef = FirebaseFirestore.instance.collection('rooms').doc(roomId);
      final docSnapshot = await docRef.get();
      int myPlayerId;

      if (!docSnapshot.exists) {
        myPlayerId = 1;
        await _createRoom(roomId);
      } else {
        myPlayerId = 2;
        await docRef.update(
            {'player2Joined': true, 'p2Ready': false, 'p2Active': true});
      }

      if (!mounted) return;
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  StandbyScreen(roomId: roomId, myPlayerId: myPlayerId)));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('エラー: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _createRoom(String roomId) async {
    final suits = ['♠', '♥', '♦', '♣'];
    final ranks = [
      'A',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      'J',
      'Q',
      'K'
    ];
    List<Map<String, dynamic>> tempPool = [];
    for (var suit in suits) {
      for (var rank in ranks) {
        tempPool.add({
          'rank': rank,
          'suit': suit,
          'isFaceUp': false,
          'isTaken': false,
          'permViewers': []
        });
      }
    }
    tempPool.shuffle();

    await FirebaseFirestore.instance.collection('rooms').doc(roomId).set({
      'cards': tempPool,
      'firstSelectedIndex': -1,
      'scores': {'1': 0, '2': 0},
      'currentTurn': 1,
      'turnCount': 1,
      'maxTurns': 50,
      'winner': 0,
      'player2Joined': false,
      'p1Ready': false,
      'p2Ready': false,
      'p1Active': true,
      'p2Active': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A3D14),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Card(
                margin: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      const Icon(Icons.grid_view,
                          size: 60, color: Colors.green),
                      const Text("真　神経衰弱",
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 25),
                      TextField(
                          controller: _roomController,
                          decoration: const InputDecoration(
                              labelText: "ルームID",
                              border: OutlineInputBorder())),
                      const SizedBox(height: 25),
                      if (isLoading)
                        const CircularProgressIndicator()
                      else
                        SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                                onPressed: _enterRoom,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green),
                                child: const Text("入室 / 作成"))),
                      const SizedBox(height: 15),
                      SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const RuleScreen())),
                              child: const Text("ルール説明"))),
                    ],
                  ),
                ),
              ),
              TextButton.icon(
                  onPressed: FirestoreService.deleteAllRooms,
                  icon: const Icon(Icons.delete_sweep,
                      color: Colors.white24, size: 16),
                  label: const Text("履歴全削除",
                      style: TextStyle(color: Colors.white24))),
            ],
          ),
        ),
      ),
    );
  }
}
