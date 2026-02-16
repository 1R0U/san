import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

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
// 1. ロビー画面（部屋作成・入室）
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
        await _createRoom(roomId);
        myPlayerId = 1;
      } else {
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
          'takenBy': 0,
        });
      }
    }

    allGenres.shuffle();
    tempPool.shuffle();

    await FirebaseFirestore.instance.collection('rooms').doc(roomId).set({
      'cards': tempPool,
      'targets': {
        '1': allGenres[0],
        '2': allGenres[1],
      },
      'scores': {'1': 0, '2': 0},
      'currentTurn': 1,
      'winner': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      body: Center(
        child: Card(
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.style, size: 64, color: Colors.blueGrey),
                const SizedBox(height: 16),
                const Text("オンライン神経衰弱",
                    style:
                        TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _roomController,
                    decoration: const InputDecoration(
                      labelText: "ルームIDを入力",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.meeting_room),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _enterRoom,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 18),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text("入室 / 作成",
                            style: TextStyle(fontSize: 18)),
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
// 2. ゲーム画面
// ---------------------------------------------------
class OnlineGameScreen extends StatefulWidget {
  final String roomId;
  final int myPlayerId;

  const OnlineGameScreen(
      {super.key, required this.roomId, required this.myPlayerId});

  @override
  State<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        if (!snapshot.data!.exists)
          return const Scaffold(body: Center(child: Text("部屋が削除されました")));

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final List<dynamic> cards = data['cards'];
        final Map<String, dynamic> targets = data['targets'];
        final Map<String, dynamic> scores = data['scores'];
        final int currentTurn = data['currentTurn'] ?? 1;
        final int winner = data['winner'] ?? 0;

        // 【プロ演出】現在のターンのプレイヤー色（P1:青, P2:赤）
        final Color turnColor = currentTurn == 1 ? Colors.blue : Colors.red;
        final bool isMyTurn = (currentTurn == widget.myPlayerId);

        if (winner != 0) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _showResultDialog(winner));
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            title: Text("部屋: ${widget.roomId} (P${widget.myPlayerId})"),
            backgroundColor: turnColor, // 手番の色に連動
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Column(
            children: [
              // ターンインジケーター
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: turnColor,
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2))
                  ],
                ),
                child: Text(
                  isMyTurn ? "★ あなたの番です ★" : "相手（P$currentTurn）が選び中...",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),

              // スコアボード
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                        child: _playerInfo(
                            1, targets['1'], scores['1'], currentTurn == 1)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text("VS",
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.black26)),
                    ),
                    Expanded(
                        child: _playerInfo(
                            2, targets['2'], scores['2'], currentTurn == 2)),
                  ],
                ),
              ),

              // カードグリッド（5x5 スクロールなし修正版）
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  // LayoutBuilderを使って利用可能なサイズを取得
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const int crossAxisCount = 5; // 5列
                      const double spacing = 10.0; // カード間の隙間

                      // 隙間の合計を引いて、1枚あたりの幅と高さを計算
                      // 横幅 = (全体の幅 - (隙間 * 4)) / 5
                      final double itemWidth = (constraints.maxWidth -
                              (spacing * (crossAxisCount - 1))) /
                          crossAxisCount;
                      // 高さ = (全体の高さ - (隙間 * 4)) / 5
                      final double itemHeight = (constraints.maxHeight -
                              (spacing * (crossAxisCount - 1))) /
                          crossAxisCount;

                      // 縦横比（アスペクト比）を計算
                      // GridViewにこれを渡すことで、高さに合わせてカードが伸縮する
                      final double childAspectRatio = itemWidth / itemHeight;

                      return GridView.builder(
                        // ★ここが重要：スクロールを無効化
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: spacing,
                          crossAxisSpacing: spacing,
                          childAspectRatio: childAspectRatio, // 計算した比率を適用
                        ),
                        itemCount: cards.length,
                        itemBuilder: (context, index) {
                          final card = cards[index];
                          final bool isTaken = card['isTaken'] ?? false;
                          final bool isFaceUp = card['isFaceUp'] ?? false;

                          return Opacity(
                            opacity: isTaken ? 0.3 : 1.0,
                            child: GestureDetector(
                              onTap: () {
                                if (isTaken || isFaceUp || !isMyTurn) return;
                                _handleTap(index, data, widget.myPlayerId);
                              },
                              child: _buildCard(card['text'], isFaceUp, isTaken,
                                  card['takenBy'], currentTurn),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showResultDialog(int winner) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(winner == widget.myPlayerId ? "🎉 勝利！" : "💀 敗北...",
            textAlign: TextAlign.center),
        content: Text(winner == widget.myPlayerId
            ? "おめでとうございます！\nターゲットをすべて集めました！"
            : "残念！相手が先に揃えました。"),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text("ロビーに戻る"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _playerInfo(int pNum, String target, int score, bool isTurn) {
    Color color = pNum == 1 ? Colors.blue : Colors.red;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isTurn ? color.withOpacity(0.1) : Colors.white,
        border: Border.all(
            color: isTurn ? color : Colors.black12, width: isTurn ? 4 : 1),
        borderRadius: BorderRadius.circular(15),
        boxShadow: isTurn
            ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)]
            : [],
      ),
      child: Column(
        children: [
          Text("P$pNum: $target",
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 16)),
          const SizedBox(height: 4),
          Text("$score / 5",
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isTurn ? color : Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildCard(
      String text, bool isFaceUp, bool isTaken, int takenBy, int currentTurn) {
    Color cardColor;
    if (isTaken) {
      cardColor = takenBy == 1 ? Colors.blue[100]! : Colors.red[100]!;
    } else if (isFaceUp) {
      cardColor = Colors.white;
    } else {
      // カードの裏面を手番の色に連動
      cardColor = currentTurn == 1 ? Colors.blue[300]! : Colors.red[300]!;
    }

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
        border:
            isFaceUp ? Border.all(color: Colors.orangeAccent, width: 4) : null,
      ),
      child: Text(
        isFaceUp || isTaken ? text : "?",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: (isFaceUp || isTaken) ? Colors.black87 : Colors.white,
        ),
      ),
    );
  }

  Future<void> _handleTap(
      int index, Map<String, dynamic> data, int myId) async {
    if (_isProcessing) return;
    if (!mounted) return;
    setState(() => _isProcessing = true);

    try {
      final docRef =
          FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        final currentData = snapshot.data() as Map<String, dynamic>;
        List<dynamic> cards = List.from(currentData['cards']);
        if (currentData['currentTurn'] != myId) return;

        String myTarget = currentData['targets'][myId.toString()];
        String cardGenre = cards[index]['genre'];

        if (cardGenre == myTarget) {
          // 正解：即座に取得してターン継続
          cards[index]['isFaceUp'] = true;
          cards[index]['isTaken'] = true;
          cards[index]['takenBy'] = myId;
          int newScore = (currentData['scores'][myId.toString()] ?? 0) + 1;
          Map<String, dynamic> newScores = Map.from(currentData['scores']);
          newScores[myId.toString()] = newScore;

          transaction.update(docRef, {
            'cards': cards,
            'scores': newScores,
            'winner': newScore >= 5 ? myId : 0,
          });
          _isProcessing = false;
        } else {
          // ハズレ：めくった後、1秒待って交代
          cards[index]['isFaceUp'] = true;
          transaction.update(docRef, {'cards': cards});
          _handleMismatch(index, cards, myId);
        }
      });
    } catch (e) {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleMismatch(int index, List<dynamic> cards, int myId) async {
    final docRef =
        FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    cards[index]['isFaceUp'] = false;
    int nextTurn = (myId == 1) ? 2 : 1;

    await docRef.update({
      'cards': cards,
      'currentTurn': nextTurn,
    });
    if (mounted) setState(() => _isProcessing = false);
  }
}
