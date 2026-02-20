import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  // --- ★追加: 盤面のみリセット (再戦用) ---
  // player2Joined フラグを維持することで、待機画面に戻ってもすぐ準備OKが押せるようにします
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
      // 2人入っている状態を維持
      'player2Joined': true,
    });
  }

  // ルームを完全に初期状態（作成直後と同じ）に戻す (誰もいなくなった時や中断時用)
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
      // 完全初期化時は player2Joined もリセットする場合があるが、
      // 今回の運用に合わせて true にしておくか false にするか選べます。
      // ここでは中断時を想定して true を維持します。
      'player2Joined': true,
    });
  }

  // 全ルーム削除
  static Future<void> deleteAllRooms() async {
    final snapshots = await _db.collection('rooms').get();
    final batch = _db.batch();
    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // 退出時のアクティブ状態更新
  static Future<void> updateActiveStatus(
      String roomId, int playerId, bool isActive) async {
    final field = playerId == 1 ? 'p1Active' : 'p2Active';
    await _db.collection('rooms').doc(roomId).update({
      field: isActive,
    });
  }
}
