import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart'; // さっき作ったファイル

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: LobbyScreen(),
  ));
}

// ---------------------------------------------------
// 1. ロビー画面（部屋を決める）
// ---------------------------------------------------
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

      int myPlayerId;

      if (!docSnapshot.exists) {
        // 部屋がないなら作る（自分はP1）
        await _createRoom(roomId);
        myPlayerId = 1;
      } else {
        // 部屋があるなら参加（自分はP2）
        // ※厳密な人数制限は省略していますが、友達と2人で遊ぶ前提です
        myPlayerId = 2;
      }

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
    // assets/cards.json を読み込んでシャッフルして保存
    final String response = await rootBundle.loadString('assets/cards.json');
    final data = json.decode(response);
    List<Map<String, dynamic>> tempPool = [];
    List<String> allGenres = [];

    for (var cat in data['categories']) {
      allGenres.add(cat['genre']);
      for (var item in cat['items']) {
        tempPool.add({
          'text': item,
          'genre': cat['genre'],
          'isFaceUp': false,
          'isTaken': false,
          'takenBy': 0, // 誰が取ったか
        });
      }
    }

    // ジャンルとカードをシャッフル
    allGenres.shuffle();
    tempPool.shuffle();

    await FirebaseFirestore.instance.collection('rooms').doc(roomId).set({
      'cards': tempPool,
      'targets': {
        '1': allGenres[0],
        '2': allGenres[1],
      },
      'scores': {'1': 0, '2': 0},
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      body: Center(
        child: Card(
          elevation: 4,
          margin: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("オンライン神経衰弱",
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                SizedBox(
                  width: 250,
                  child: TextField(
                    controller: _roomController,
                    decoration: const InputDecoration(
                      labelText: "合言葉（ルームID）",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.meeting_room),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _enterRoom,
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 15)),
                        child: const Text("入室 / 作成"),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------
// 2. ゲーム画面（Firestoreと同期）
// ---------------------------------------------------
class OnlineGameScreen extends StatelessWidget {
  final String roomId;
  final int myPlayerId;

  const OnlineGameScreen(
      {super.key, required this.roomId, required this.myPlayerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        title: Text("部屋: $roomId (あなたはP$myPlayerId)"),
        backgroundColor: myPlayerId == 1 ? Colors.blue : Colors.red,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .doc(roomId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final List<dynamic> cards = data['cards'];
          final Map<String, dynamic> targets = data['targets'];
          final Map<String, dynamic> scores = data['scores'];

          // 勝利判定
          if (scores[myPlayerId.toString()] >= 5) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showDialog(
                context: context,
                builder: (_) =>
                    const AlertDialog(content: Text("🎉 あなたの勝ちです！")),
              );
            });
          }

          return Column(
            children: [
              // スコア表示
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                        child: _playerInfo(
                            1, targets['1'], scores['1'], myPlayerId == 1)),
                    const Text(" VS ",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey)),
                    Expanded(
                        child: _playerInfo(
                            2, targets['2'], scores['2'], myPlayerId == 2)),
                  ],
                ),
              ),
              // カードグリッド
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 2.0,
                        ),
                        itemCount: cards.length,
                        itemBuilder: (context, index) {
                          final card = cards[index];
                          final bool isTaken = card['isTaken'] ?? false;

                          return Opacity(
                            opacity: isTaken ? 0.0 : 1.0,
                            child: GestureDetector(
                              onTap: () => isTaken
                                  ? null
                                  : _handleTap(index, card,
                                      targets[myPlayerId.toString()]),
                              child: _buildCard(
                                  card['text'], card['isFaceUp'], myPlayerId),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _playerInfo(int pNum, String target, int score, bool isMe) {
    Color color = pNum == 1 ? Colors.blue : Colors.red;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe ? color.withOpacity(0.1) : Colors.transparent,
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text("P$pNum: $target",
              style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          Text("$score / 5",
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCard(String text, bool isFaceUp, int myId) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isFaceUp
            ? Colors.white
            : (myId == 1 ? Colors.blue[300] : Colors.red[300]),
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
      ),
      child: Text(
        isFaceUp ? text : "?",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isFaceUp ? Colors.black87 : Colors.white,
        ),
      ),
    );
  }

  // カードをタップした時の処理（トランザクション）
  Future<void> _handleTap(
      int index, Map<String, dynamic> cardData, String myTarget) async {
    if (cardData['isFaceUp']) return; // すでに開いてたら何もしない

    final docRef = FirebaseFirestore.instance.collection('rooms').doc(roomId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      List<dynamic> currentCards = List.from(data['cards']);
      Map<String, dynamic> currentScores = Map.from(data['scores']);

      // 誰かが先に取ってないか確認
      if (currentCards[index]['isTaken'] == true) return;

      // 1. めくる
      currentCards[index]['isFaceUp'] = true;
      transaction.update(docRef, {'cards': currentCards});

      // 2. 判定ロジック（少し待つのではなく、めくった状態で即判定して書き込む）
      // ※簡易化のため、めくる処理と判定を同時に行います
      String genre = currentCards[index]['genre'];

      if (genre == myTarget) {
        // 当たり！
        currentCards[index]['isTaken'] = true;
        currentCards[index]['takenBy'] = myPlayerId;
        currentScores[myPlayerId.toString()] =
            (currentScores[myPlayerId.toString()] ?? 0) + 1;
        transaction
            .update(docRef, {'cards': currentCards, 'scores': currentScores});
      } else {
        // ハズレ！あとで裏返す処理が必要だが、
        // 簡易版として「1秒後に裏返す」のはクライアント側ではなく、
        // 本来はCloud Functionsか、「最後にめくった時間」を見て制御するのがベスト。
        // ここでは「めくりっぱなし」を防ぐため、1秒後に「誰も取ってなければ裏返す」コマンドを送る簡易実装にします。
        _scheduleFaceDown(index);
      }
    });
  }

  void _scheduleFaceDown(int index) async {
    await Future.delayed(const Duration(seconds: 1));
    final docRef = FirebaseFirestore.instance.collection('rooms').doc(roomId);
    // トランザクションは使わず、単に裏返す（取られてなければ）
    // ※競合は許容する（カジュアルゲームなので）
    docRef.get().then((snapshot) {
      if (!snapshot.exists) return;
      List<dynamic> cards = List.from(snapshot.get('cards'));
      if (cards[index]['isTaken'] == false) {
        cards[index]['isFaceUp'] = false;
        docRef.update({'cards': cards});
      }
    });
  }
}
