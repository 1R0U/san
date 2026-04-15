import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../models/player_model.dart';
import '../widgets/standby_player_card.dart';
import 'online_game_screen.dart';

class StandbyScreen extends StatelessWidget {
  final String roomId;
  final int myPlayerId;
  const StandbyScreen(
      {super.key, required this.roomId, required this.myPlayerId});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await FirestoreService.leaveRoomAndCleanup(roomId, myPlayerId);
        if (context.mounted) Navigator.pop(context);
      },
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .doc(roomId)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData || !snap.data!.exists)
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          final data = snap.data!.data() as Map<String, dynamic>;
          final playersMap = data['players'] as Map<String, dynamic>;
          if (playersMap[myPlayerId.toString()] == null)
            return const Scaffold(body: Center(child: Text("データエラー")));

          final meData = PlayerModel.fromMap(playersMap[myPlayerId.toString()]);
          final activePlayers =
              playersMap.values.where((p) => p['isActive'] == true).toList();
          final allReady = activePlayers.every((p) => p['isReady'] == true) &&
              activePlayers.length >= 2;

          if (data['isStarted'] == true) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
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
              title: Text("Room: $roomId"),
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () async {
                  await FirestoreService.leaveRoomAndCleanup(
                      roomId, myPlayerId);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.8),
                    itemCount: 8,
                    itemBuilder: (context, i) {
                      final p = playersMap[(i + 1).toString()];
                      return StandbyPlayerCard(
                        label: p?['name'] ?? "空き",
                        isReady: p?['isReady'] ?? false,
                        isJoined: p?['isActive'] ?? false,
                        isMe: myPlayerId == (i + 1),
                        onEdit: myPlayerId == (i + 1)
                            ? () => _editName(context, roomId, meData)
                            : null,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                meData.isReady ? Colors.orange : Colors.green),
                        onPressed: () => FirestoreService.updatePlayer(
                            roomId,
                            PlayerModel(
                                id: myPlayerId,
                                name: meData.name,
                            layoutMode: meData.layoutMode,
                                isActive: true,
                                isReady: !meData.isReady)),
                        child: Text(meData.isReady ? "解除" : "準備OK"),
                      ),
                      if (myPlayerId == 1 && allReady)
                        TextButton(
                            onPressed: () => FirebaseFirestore.instance
                                .collection('rooms')
                                .doc(roomId)
                                .update({'isStarted': true}),
                            child: const Text("開始！",
                                style: TextStyle(
                                    color: Colors.yellow,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold))),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  void _editName(BuildContext context, String rid, PlayerModel me) {
    final c = TextEditingController(text: me.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("名前変更"),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("キャンセル")),
          TextButton(
            child: const Text("保存"),
            onPressed: () {
              FirestoreService.updatePlayer(
                  rid,
                  PlayerModel(
                      id: me.id,
                      name: c.text,
                    layoutMode: me.layoutMode,
                      isActive: true,
                      isReady: me.isReady));
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}
