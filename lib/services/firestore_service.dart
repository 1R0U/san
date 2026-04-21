import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player_model.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  static List<Map<String, dynamic>> _buildShuffledCards() {
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
    final cards = <Map<String, dynamic>>[];
    for (final s in suits) {
      for (final r in ranks) {
        cards.add({
          'rank': r,
          'suit': s,
          'isFaceUp': false,
          'isTaken': false,
          'permViewers': []
        });
      }
    }
    cards.shuffle();
    return cards;
  }

  static Future<void> ensureRoomExists(String roomId) async {
    final docRef = _db.collection('rooms').doc(roomId);
    final snap = await docRef.get();
    if (snap.exists) return;
    await resetRoomFull8(roomId);
  }

  static Future<void> addCpuPlayers(
      String roomId, int cpuCount, int cpuLevel) async {
    if (cpuCount <= 0) return;
    final docRef = _db.collection('rooms').doc(roomId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;

      final players = Map<String, dynamic>.from(snap.data()?['players'] ?? {});
      int added = 0;

      for (int slot = 1; slot <= 8 && added < cpuCount; slot++) {
        final current = players[slot.toString()];
        final isEmpty = current == null || current['isActive'] == false;
        if (!isEmpty) continue;

        players[slot.toString()] = PlayerModel(
          id: slot,
          name: 'CPU $slot',
          isCPU: true,
          cpuLevel: cpuLevel,
          isActive: true,
          isReady: true,
        ).toMap();
        added++;
      }

      tx.update(docRef, {'players': players});
    });
  }

  static Future<bool> claimCpuMove(String roomId, int turn) async {
    final docRef = _db.collection('rooms').doc(roomId);
    return _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return false;
      final data = snap.data() as Map<String, dynamic>;
      if ((data['currentTurn'] ?? 1) != turn) return false;
      if ((data['cpuMoveLock'] ?? 0) == turn) return false;
      final players = Map<String, dynamic>.from(data['players'] ?? {});
      final current = players[turn.toString()];
      if (current == null || current['isCPU'] != true) return false;
      tx.update(docRef, {'cpuMoveLock': turn});
      return true;
    });
  }

  static Future<void> releaseCpuMove(String roomId) async {
    await _db.collection('rooms').doc(roomId).update({'cpuMoveLock': 0});
  }

  static Future<int?> getEmptySlot(String roomId) async {
    final snap = await _db.collection('rooms').doc(roomId).get();
    if (!snap.exists) return 1;
    final players = snap.data()?['players'] as Map? ?? {};
    for (int i = 1; i <= 8; i++) {
      if (players[i.toString()] == null ||
          players[i.toString()]['isActive'] == false) return i;
    }
    return null;
  }

  static Future<void> updatePlayer(String roomId, PlayerModel p) async {
    await _db
        .collection('rooms')
        .doc(roomId)
        .update({'players.${p.id}': p.toMap()});
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

  static Future<void> updateActiveStatus(
      String roomId, int playerId, bool isActive) async {
    await _db.collection('rooms').doc(roomId).update({
      'players.$playerId.isActive': isActive,
      'players.$playerId.isReady': false,
    });
  }

  static Future<void> resetRoomFull8(String roomId) async {
    await _db.collection('rooms').doc(roomId).set({
      'cards': _buildShuffledCards(),
      'players': {},
      'cpuCount': 0,
      'cpuLevel': 1,
      'turnOrder': [],
      'currentTurn': 1,
      'turnCount': 1,
      'cpuMoveLock': 0,
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
    players.forEach((k, v) {
      v['score'] = 0;
      v['isReady'] = false;
    });
    await resetRoomFull8(roomId);
    await _db.collection('rooms').doc(roomId).update({'players': players});
  }
}
