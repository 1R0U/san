import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  // プレイヤー名の更新
  static Future<void> updatePlayerName(
      String roomId, int playerId, String newName) async {
    final field = playerId == 1 ? 'p1Name' : 'p2Name';
    await _db.collection('rooms').doc(roomId).update({field: newName});
  }

  // 盤面のみリセット (対戦終了後の再戦用)
  static Future<void> resetBoardOnly(String roomId) async {
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

    List<Map<String, dynamic>> newCards = [];
    for (var s in suits) {
      for (var r in ranks) {
        newCards.add({
          'rank': r,
          'suit': s,
          'isFaceUp': false,
          'isTaken': false,
          'permViewers': []
        });
      }
    }
    newCards.shuffle();

    await _db.collection('rooms').doc(roomId).update({
      'cards': newCards,
      'scores': {'1': 0, '2': 0},
      'currentTurn': 1,
      'turnCount': 1,
      'winner': 0,
      'firstSelectedIndex': -1,
      'latestEffect': null,
      'activeEffect': null,
      'highlightedIndices': [],
      'p1Ready': false,
      'p2Ready': false,
      'p1InGame': false,
      'p2InGame': false,
      'player2Joined': true, // 相手がいるのでtrueを維持
    });
  }

  // ルームの中断・初期化リセット
  static Future<void> resetRoomFully(String roomId) async {
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
    List<Map<String, dynamic>> newCards = [];
    for (var s in suits) {
      for (var r in ranks) {
        newCards.add({
          'rank': r,
          'suit': s,
          'isFaceUp': false,
          'isTaken': false,
          'permViewers': []
        });
      }
    }
    newCards.shuffle();

    await _db.collection('rooms').doc(roomId).update({
      'cards': newCards,
      'scores': {'1': 0, '2': 0},
      'currentTurn': 1,
      'turnCount': 1,
      'maxTurns': 50,
      'winner': 0,
      'firstSelectedIndex': -1,
      'latestEffect': null,
      'activeEffect': null,
      'highlightedIndices': [],
      'p1Ready': false,
      'p2Ready': false,
      'p1InGame': false,
      'p2InGame': false,
      // ★ここを true に修正 (二人は待機画面に戻っただけで部屋にはいるため)
      'player2Joined': true,
    });
  }

  static Future<void> deleteAllRooms() async {
    final snapshots = await _db.collection('rooms').get();
    final batch = _db.batch();
    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  static Future<void> updateActiveStatus(
      String roomId, int playerId, bool isActive) async {
    final field = playerId == 1 ? 'p1Active' : 'p2Active';
    await _db.collection('rooms').doc(roomId).update({field: isActive});
  }
}
