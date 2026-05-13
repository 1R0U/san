import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player_model.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  static const _allSuits = ['♠', '♥', '♦', '♣', '♤', '♡', '♢', '♧'];
  static const _ranks = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q'];

  static List<Map<String, dynamic>> _buildShuffledCards([int cardCount = 48]) {
    final suitCount = (cardCount / 12).round().clamp(1, 8);
    final suits = _allSuits.take(suitCount).toList();
    final cards = <Map<String, dynamic>>[];
    for (final s in suits) {
      for (final r in _ranks) {
        cards.add({'rank': r, 'suit': s, 'isFaceUp': false, 'isTaken': false, 'permViewers': []});
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
    cpuCount = cpuCount.clamp(0, 8);
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

  static Future<void> startGameWithCpu(
      String roomId, int cpuCount, int cpuLevel) async {
    cpuCount = cpuCount.clamp(0, 8);
    final docRef = _db.collection('rooms').doc(roomId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;
      final players = Map<String, dynamic>.from(data['players'] ?? {});
      final cpuSlotLevels =
          Map<String, dynamic>.from(data['cpuSlotLevels'] ?? {});
      final cpuSelectedSlots =
          Map<String, dynamic>.from(data['cpuSelectedSlots'] ?? {});

      int added = 0;
      final selectedSlots = cpuSelectedSlots.entries
          .where((e) => e.value == true)
          .map((e) => int.tryParse(e.key) ?? 0)
          .where((s) => s >= 1 && s <= 8)
          .toList()
        ..sort();

      for (final slot in selectedSlots) {
        final current = players[slot.toString()];
        final isEmpty = current == null || current['isActive'] == false;
        if (!isEmpty) continue;

        final slotLevel = (cpuSlotLevels['$slot'] ?? cpuLevel) as int;

        players[slot.toString()] = PlayerModel(
          id: slot,
          name: 'CPU $slot',
          isCPU: true,
          cpuLevel: slotLevel,
          isActive: true,
          isReady: true,
        ).toMap();
        added++;
      }

      if (added < cpuCount) {
        for (int slot = 1; slot <= 8 && added < cpuCount; slot++) {
          final current = players[slot.toString()];
          final isEmpty = current == null || current['isActive'] == false;
          if (!isEmpty) continue;

          final slotLevel = (cpuSlotLevels['$slot'] ?? cpuLevel) as int;
          players[slot.toString()] = PlayerModel(
            id: slot,
            name: 'CPU $slot',
            isCPU: true,
            cpuLevel: slotLevel,
            isActive: true,
            isReady: true,
          ).toMap();
          added++;
        }
      }

      final ids = players.values
          .where((p) => p['isActive'] == true)
          .map<int>((p) => p['id'] as int)
          .toList()
        ..shuffle();
      if (ids.isEmpty) return;

      tx.update(docRef, {
        'players': players,
        'isStarted': true,
        'turnOrder': ids,
        'currentTurn': ids.first,
        'turnCount': 1,
        'cpuMoveLock': 0,
        'cpuMoveLockAt': null,
      });
    });
  }

  static Future<bool> claimCpuMove(String roomId, int turn) async {
    final docRef = _db.collection('rooms').doc(roomId);
    return _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return false;
      final data = snap.data() as Map<String, dynamic>;
      if ((data['currentTurn'] ?? 1) != turn) return false;

      final lockTurn = data['cpuMoveLock'] ?? 0;
      final lockAt = data['cpuMoveLockAt'];
      if (lockTurn == turn) {
        if (lockAt is Timestamp) {
          final sec = DateTime.now().difference(lockAt.toDate()).inSeconds;
          if (sec < 8) return false;
        } else {
          return false;
        }
      }

      final players = Map<String, dynamic>.from(data['players'] ?? {});
      final current = players[turn.toString()];
      if (current == null || current['isCPU'] != true) return false;
      tx.update(docRef, {
        'cpuMoveLock': turn,
        'cpuMoveLockAt': Timestamp.now(),
      });
      return true;
    });
  }

  static Future<void> releaseCpuMove(String roomId) async {
    await _db.collection('rooms').doc(roomId).update({
      'cpuMoveLock': 0,
      'cpuMoveLockAt': null,
    });
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

  // 退出 & 誰もいなければ部屋を削除
  static Future<void> leaveRoomAndCleanup(String roomId, int playerId) async {
    final docRef = _db.collection('rooms').doc(roomId);
    await docRef.update({
      'players.$playerId.isActive': false,
      'players.$playerId.isReady': false,
    });

    final snap = await docRef.get();
    if (!snap.exists) return;
    final players = snap.data()?['players'] as Map<String, dynamic>? ?? {};
    final isRoomEmpty = !players.values.any((p) => p['isActive'] == true);

    if (isRoomEmpty) {
      await docRef.delete();
    }
  }

  static Future<void> updateActiveStatus(
      String roomId, int playerId, bool isActive) async {
    await _db.collection('rooms').doc(roomId).update({
      'players.$playerId.isActive': isActive,
      'players.$playerId.isReady': false,
    });
  }

  static Future<void> updateRoomSettings(String roomId, {int? cardCount, int? maxTurns}) async {
    final updates = <String, dynamic>{};
    if (cardCount != null) {
      updates['cardCount'] = cardCount;
      updates['cards'] = _buildShuffledCards(cardCount);
    }
    if (maxTurns != null) updates['maxTurns'] = maxTurns;
    if (updates.isNotEmpty) {
      await _db.collection('rooms').doc(roomId).update(updates);
    }
  }

  static Future<void> resetRoomFull8(String roomId) async {
    await _db.collection('rooms').doc(roomId).set({
      'cards': _buildShuffledCards(48),
      'players': {},
      'cpuCount': 0,
      'cpuLevel': 1,
      'cpuSlotLevels': {},
      'cpuSelectedSlots': {},
      'turnOrder': [],
      'currentTurn': 1,
      'turnCount': 1,
      'cpuMoveLock': 0,
      'cpuMoveLockAt': null,
      'isStarted': false,
      'winner': 0,
      'firstSelectedIndex': -1,
      'latestEffect': null,
      'effectTimestamp': null,
      'cardCount': 48,
      'maxTurns': 50,
    });
  }

  static Future<void> resetBoardOnly(String roomId) async {
    final snap = await _db.collection('rooms').doc(roomId).get();
    if (!snap.exists) return;
    final data = snap.data()!;
    final prevCpuCount = (data['cpuCount'] ?? 0) as int;
    final prevCpuLevel = (data['cpuLevel'] ?? 1) as int;
    final prevCpuSlotLevels =
        Map<String, dynamic>.from(data['cpuSlotLevels'] ?? {});
    final prevCpuSelectedSlots =
        Map<String, dynamic>.from(data['cpuSelectedSlots'] ?? {});
    final players = Map<String, dynamic>.from(data['players'] ?? {});
    players.forEach((k, v) {
      v['score'] = 0;
      v['isReady'] = false;
      if (v['isCPU'] == true) v['isActive'] = false;
    });
    final prevCardCount = (data['cardCount'] ?? 48) as int;
    final prevMaxTurns = (data['maxTurns'] ?? 50) as int;
    // Single atomic set — avoids the race condition where players:{} is
    // briefly visible between resetRoomFull8 and the subsequent update.
    await _db.collection('rooms').doc(roomId).set({
      'cards': _buildShuffledCards(prevCardCount),
      'players': players,
      'cpuCount': prevCpuCount,
      'cpuLevel': prevCpuLevel,
      'cpuSlotLevels': prevCpuSlotLevels,
      'cpuSelectedSlots': prevCpuSelectedSlots,
      'turnOrder': [],
      'currentTurn': 1,
      'turnCount': 1,
      'cpuMoveLock': 0,
      'cpuMoveLockAt': null,
      'isStarted': false,
      'winner': 0,
      'firstSelectedIndex': -1,
      'latestEffect': null,
      'effectTimestamp': null,
      'cardCount': prevCardCount,
      'maxTurns': prevMaxTurns,
    });
  }
}
