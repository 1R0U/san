import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player_model.dart';
import '../services/firestore_service.dart';
import '../logic/online_standby_actions.dart';
import '../widgets/online_standby_view.dart';
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
          if (!snap.hasData) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (!snap.data!.exists) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) Navigator.popUntil(context, (r) => r.isFirst);
            });
            return const Scaffold(
              backgroundColor: Color(0xFF0A3D14),
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final data = snap.data!.data() as Map<String, dynamic>;
          final playersMap = data['players'] as Map<String, dynamic>;
          if (playersMap[myPlayerId.toString()] == null)
            return const Scaffold(body: Center(child: Text("データエラー")));

          final meData = PlayerModel.fromMap(playersMap[myPlayerId.toString()]);
          final activePlayers =
              playersMap.values.where((p) => p['isActive'] == true).toList();
          final activeHumans = activePlayers
              .where((p) => (p['isCPU'] ?? false) != true)
              .toList();
          final activeCpus = activePlayers
              .where((p) => (p['isCPU'] ?? false) == true)
              .toList();
          final cpuSelectedSlotsMap = Map<String, dynamic>.from(
              data['cpuSelectedSlots'] as Map<String, dynamic>? ?? {});
          final selectedCpuSlots = cpuSelectedSlotsMap.entries
              .where((e) => e.value == true)
              .map((e) => int.tryParse(e.key) ?? 0)
              .where((s) => s >= 1 && s <= 8)
              .toSet();
          final selectedCpuCount = selectedCpuSlots.length;
          final cpuLevel = (data['cpuLevel'] ?? 1) as int;
          final cpuSlotLevels = Map<String, dynamic>.from(
              data['cpuSlotLevels'] as Map<String, dynamic>? ?? {});
          final cardCount = (data['cardCount'] ?? 48) as int;
          final maxTurns = (data['maxTurns'] ?? 50) as int;
          final allReady = activeHumans.every((p) => p['isReady'] == true) &&
              activeHumans.length + selectedCpuCount >= 2;

          final previewCpuSlots = <int>{};
          if (data['isStarted'] != true) {
            for (final slot in selectedCpuSlots) {
              final p = playersMap[slot.toString()];
              final occupiedByHuman =
                  p != null && p['isActive'] == true && p['isCPU'] != true;
              if (!occupiedByHuman) previewCpuSlots.add(slot);
            }
          }

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

          return OnlineStandbyView(
            roomId: roomId,
            myPlayerId: myPlayerId,
            meData: meData,
            playersMap: playersMap,
            activeHumans: activeHumans.cast<Map<String, dynamic>>(),
            activeCpus: activeCpus.cast<Map<String, dynamic>>(),
            cardCount: cardCount,
            maxTurns: maxTurns,
            onCardCountChanged: (v) => FirestoreService.updateRoomSettings(roomId, cardCount: v),
            onMaxTurnsChanged: (v) => FirestoreService.updateRoomSettings(roomId, maxTurns: v),
            selectedCpuSlots: selectedCpuSlots,
            selectedCpuCount: selectedCpuCount,
            cpuLevel: cpuLevel,
            cpuSlotLevels: cpuSlotLevels,
            allReady: allReady,
            previewCpuSlots: previewCpuSlots,
            onBack: () async {
              await FirestoreService.leaveRoomAndCleanup(roomId, myPlayerId);
              if (context.mounted) Navigator.pop(context);
            },
            onToggleReady: () => FirestoreService.updatePlayer(
              roomId,
              PlayerModel(
                id: myPlayerId,
                name: meData.name,
                layoutMode: meData.layoutMode,
                isActive: true,
                isReady: !meData.isReady,
              ),
            ),
            onStart: () async {
              await FirestoreService.startGameWithCpu(
                roomId,
                selectedCpuCount,
                (data['cpuLevel'] ?? 1) as int,
              );
            },
            onEditName: (slot) => OnlineStandbyActions.editName(context, roomId, meData),
            onToggleCpuSlot: (slot, enable, defaultLevel, selectedCount) =>
                OnlineStandbyActions.toggleCpuSlot(
              roomId,
              slot,
              enable,
              defaultLevel,
              selectedCount,
            ),
            onEditCpuLevel: (slot, currentLevel, defaultLevel) =>
                OnlineStandbyActions.editCpuLevel(
              context,
              roomId,
              slot,
              currentLevel,
              defaultLevel,
            ),
          );
        },
      ),
    );
  }
}
