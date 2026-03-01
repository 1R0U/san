import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'online_game_screen.dart';
import 'rule_screen.dart';
import '../widgets/standby_player_card.dart';
import '../services/firestore_service.dart';

class StandbyScreen extends StatelessWidget {
  final String roomId;
  final int myPlayerId;
  const StandbyScreen(
      {super.key, required this.roomId, required this.myPlayerId});

  // ★名前変更ダイアログを表示
  void _showNameEditDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("名前を変更"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "新しい名前を入力"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("キャンセル")),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await FirestoreService.updatePlayerName(
                    roomId, myPlayerId, newName);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("保存"),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveStandby(BuildContext context) async {
    await FirestoreService.updateActiveStatus(roomId, myPlayerId, false);
    await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
      myPlayerId == 1 ? 'p1Ready' : 'p2Ready': false,
    });
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _leaveStandby(context);
      },
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .doc(roomId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists)
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String p1Name = data['p1Name'] ?? "P1";
          final String p2Name = data['p2Name'] ?? "P2";
          final bool p1Ready = data['p1Ready'] ?? false;
          final bool p2Ready = data['p2Ready'] ?? false;
          final bool player2Joined = data['player2Joined'] ?? false;
          final bool isIMReady = myPlayerId == 1 ? p1Ready : p2Ready;

          if (p1Ready && p2Ready) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(roomId)
                  .update({'p1InGame': true, 'p2InGame': true});
              if (context.mounted)
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => OnlineGameScreen(
                            roomId: roomId, myPlayerId: myPlayerId)));
            });
          }

          return Scaffold(
            backgroundColor: const Color(0xFF0A3D14),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _leaveStandby(context)),
              title: const Text("対戦待機", style: TextStyle(fontSize: 16)),
              centerTitle: true,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("対戦待機中",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      StandbyPlayerCard(
                        label: p1Name,
                        isReady: p1Ready,
                        isJoined: data['p1Active'] ?? true,
                        isMe: myPlayerId == 1,
                        onEdit: () => _showNameEditDialog(context, p1Name), // ★
                      ),
                      StandbyPlayerCard(
                        label: p2Name,
                        isReady: p2Ready,
                        isJoined: data['p2Active'] ?? false,
                        isMe: myPlayerId == 2,
                        onEdit: () => _showNameEditDialog(context, p2Name), // ★
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                  SizedBox(
                      width: 220,
                      height: 60,
                      child: ElevatedButton(
                          onPressed: player2Joined
                              ? () => FirebaseFirestore.instance
                                      .collection('rooms')
                                      .doc(roomId)
                                      .update({
                                    myPlayerId == 1 ? 'p1Ready' : 'p2Ready':
                                        !isIMReady
                                  })
                              : null,
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isIMReady ? Colors.orange : Colors.green,
                              foregroundColor: Colors.white),
                          child: Text(isIMReady ? "解除する" : "準備OK！",
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)))),
                  const SizedBox(height: 15),
                  SizedBox(
                      width: 220,
                      height: 50,
                      child: OutlinedButton(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RuleScreen())),
                          style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white)),
                          child: const Text("ルールを確認",
                              style: TextStyle(color: Colors.white)))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
