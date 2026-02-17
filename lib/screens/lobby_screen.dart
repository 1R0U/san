import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // rootBundle用
import 'package:cloud_firestore/cloud_firestore.dart';
import 'online_game_screen.dart'; // さっき作ったファイルをインポート

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

      int myPlayerId = docSnapshot.exists ? 2 : 1;
      if (!docSnapshot.exists) await _createRoom(roomId);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              OnlineGameScreen(roomId: roomId, myPlayerId: myPlayerId),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('エラー: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _createRoom(String roomId) async {
    // 52枚のカードを生成
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
        tempPool.add(
            {'rank': rank, 'suit': suit, 'isFaceUp': false, 'isTaken': false});
      }
    }
    tempPool.shuffle();

    // 最大ターン数
    const int maxTurns = 30;

    await FirebaseFirestore.instance.collection('rooms').doc(roomId).set({
      'cards': tempPool,
      'firstSelectedIndex': -1,
      'scores': {'1': 0, '2': 0},
      'currentTurn': 1,
      'turnCount': 1,
      'maxTurns': maxTurns,
      'winner': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[900],
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            margin: const EdgeInsets.all(20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.grid_view, size: 60, color: Colors.green),
                  const SizedBox(height: 10),
                  const Text("ポイント制 52枚対戦",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(
                      controller: _roomController,
                      decoration: const InputDecoration(labelText: "ルームID")),
                  const SizedBox(height: 20),
                  isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _enterRoom, child: const Text("入室 / 作成")),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
