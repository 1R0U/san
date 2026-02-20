import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'online_game_screen.dart';
import 'rule_screen.dart';
import '../widgets/standby_player_card.dart';

class StandbyScreen extends StatelessWidget {
  final String roomId;
  final int myPlayerId;
  const StandbyScreen(
      {super.key, required this.roomId, required this.myPlayerId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists)
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final bool p1Ready = data['p1Ready'] ?? false;
        final bool p2Ready = data['p2Ready'] ?? false;
        final bool player2Joined = data['player2Joined'] ?? false;
        final bool isIMReady = myPlayerId == 1 ? p1Ready : p2Ready;

        // ★2人とも準備OKになったら「InGame」フラグを立てて開始
        if (p1Ready && p2Ready) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await FirebaseFirestore.instance
                .collection('rooms')
                .doc(roomId)
                .update({
              'p1InGame': true,
              'p2InGame': true,
            });
            if (context.mounted) {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => OnlineGameScreen(
                          roomId: roomId, myPlayerId: myPlayerId)));
            }
          });
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0A3D14),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text("あなたは プレイヤー $myPlayerId です",
                style: const TextStyle(fontSize: 14, color: Colors.white70)),
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
                const SizedBox(height: 10),
                Text("Room: $roomId",
                    style: const TextStyle(color: Colors.yellowAccent)),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    StandbyPlayerCard(
                        label: "P1",
                        isReady: p1Ready,
                        isJoined: true,
                        isMe: myPlayerId == 1),
                    StandbyPlayerCard(
                        label: "P2",
                        isReady: p2Ready,
                        isJoined: player2Joined,
                        isMe: myPlayerId == 2),
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
                                isIMReady ? Colors.orange : Colors.green),
                        child: Text(isIMReady ? "解除する" : "準備OK！",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)))),
                const SizedBox(height: 20),
                SizedBox(
                    width: 220,
                    height: 50,
                    child: OutlinedButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RuleScreen())),
                        child: const Text("ルールを確認",
                            style: TextStyle(color: Colors.white)))),
              ],
            ),
          ),
        );
      },
    );
  }
}
