import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player_model.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  static Future<int?> getEmptySlot(String roomId) async {
    final snap = await _db.collection('rooms').doc(roomId).get();
    if (!snap.exists) return 1;
    final players = snap.data()?['players'] as Map? ?? {};
    for (int i = 1; i <= 8; i++) {
      if (players[i.toString()] == null || players[i.toString()]['isActive'] == false) return i;
    }
    return null;
  }

  static Future<void> updatePlayer(String roomId, PlayerModel p) async {
    await _db.collection('rooms').doc(roomId).update({'players.${p.id}': p.toMap()});
  }

  // 退出 & 誰もいなければリセット
  static Future<void> leaveRoomAndCleanup(String roomId, int playerId) async {
    final docRef = _db.collection('rooms').doc(roomId);
    await docRef.update({
      'players.$playerId.isActive': false,
      'players.$playerId.isReady': false,
    });

    final snap = await docRef.get();
    if (!snap.exists) return;
    final players = snap.data()?['players'] as Map<String, dynamic>? ?? {};
    bool isRoomEmpty = !players.values.any((p) => p['isActive'] == true);

    if (isRoomEmpty) {
      await resetRoomFull8(roomId);
    }
  }

  static Future<void> updateActiveStatus(String roomId, int playerId, bool isActive) async {
    await _db.collection('rooms').doc(roomId).update({
      'players.$playerId.isActive': isActive,
      'players.$playerId.isReady': false,
    });
  }

  static Future<void> resetRoomFull8(String roomId) async {
    final suits = ['♠','♥','♦','♣'];
    final ranks = ['A','2','3','4','5','6','7','8','9','10','J','Q','K'];
    List<Map<String, dynamic>> cards = [];
    for (var s in suits) {
      for (var r in ranks) {
        cards.add({'rank': r, 'suit': s, 'isFaceUp': false, 'isTaken': false, 'permViewers': []});
      }
    }
    await _db.collection('rooms').doc(roomId).set({
      'cards': cards..shuffle(),
      'players': {},
      'currentTurn': 1,
      'turnCount': 1,
      'isStarted': false,
      'winner': 0,
      'firstSelectedIndex': -1,
      'latestEffect': null,
      'effectTimestamp': null,
    });
  }

  static Future<void> resetBoardOnly(String roomId) async {
    final snap = await _db.collection('rooms').doc(roomId).get();
    if (!snap.exists) return;
    Map players = Map.from(snap.data()!['players']);
    players.forEach((k, v) { v['score'] = 0; v['isReady'] = false; });
    await resetRoomFull8(roomId);
    await _db.collection('rooms').doc(roomId).update({'players': players});
  }
}