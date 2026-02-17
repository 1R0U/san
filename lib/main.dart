import 'dart:async';
import 'package:flutter/material.dart';
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
// 1. ロビー画面
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

      int myPlayerId = docSnapshot.exists ? 2 : 1;
      if (!docSnapshot.exists) await _createRoom(roomId);

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

    List<Map<String, dynamic>> tempPool = [];
    for (var suit in suits) {
      for (var rank in ranks) {
        tempPool.add(
            {'rank': rank, 'suit': suit, 'isFaceUp': false, 'isTaken': false});
      }
    }
    tempPool.shuffle();

    await FirebaseFirestore.instance.collection('rooms').doc(roomId).set({
      'cards': tempPool,
      'firstSelectedIndex': -1,
      'scores': {'1': 0, '2': 0},
      'currentTurn': 1,
      'winner': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[900],
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            margin: const EdgeInsets.all(20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.grid_view, size: 60, color: Colors.green),
                  const SizedBox(height: 10),
                  const Text("52枚フルデッキ対戦",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(
                      controller: _roomController,
                      decoration: const InputDecoration(labelText: "ルームID")),
                  const SizedBox(height: 20),
                  isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _enterRoom, child: const Text("入室 / 作成")),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------
// 2. ゲーム画面 (52枚スクロールなし)
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
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final List<dynamic> cards = data['cards'];
        final Map scores = data['scores'];
        final int turn = data['currentTurn'];
        final bool isMyTurn = (turn == widget.myPlayerId);

        if (data['winner'] != 0) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _showResult(data['winner'], scores));
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0A3D14),
          appBar: AppBar(
            toolbarHeight: 40,
            title: Text("P${widget.myPlayerId} 部屋:${widget.roomId}",
                style: const TextStyle(fontSize: 14)),
            backgroundColor: turn == 1 ? Colors.blue[900] : Colors.red[900],
          ),
          body: Column(
            children: [
              _buildHeader(isMyTurn, turn, scores),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: LayoutBuilder(builder: (context, constraints) {
                    // 13列 × 4行 = 52枚
                    return GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 13,
                        mainAxisSpacing: 2,
                        crossAxisSpacing: 2,
                        childAspectRatio: 0.8, // 縦長のカード
                      ),
                      itemCount: cards.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _handleTap(index, data),
                          child: _CardMini(
                            card: cards[index],
                            isMyTurn: isMyTurn,
                            pColor: turn == 1 ? Colors.blue : Colors.red,
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isMyTurn, int turn, Map scores) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.black26,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _scoreText(1, scores['1'], turn == 1),
          Text(isMyTurn ? "YOUR TURN" : "WAITING...",
              style: const TextStyle(
                  color: Colors.yellow,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
          _scoreText(2, scores['2'], turn == 2),
        ],
      ),
    );
  }

  Widget _scoreText(int id, int score, bool active) {
    return Text("P$id: $score",
        style: TextStyle(
            color: active ? Colors.white : Colors.white38,
            fontWeight: active ? FontWeight.bold : FontWeight.normal));
  }

  Future<void> _handleTap(int index, Map<String, dynamic> data) async {
    if (_isProcessing || data['currentTurn'] != widget.myPlayerId) return;
    final cards = List.from(data['cards']);
    if (cards[index]['isFaceUp'] || cards[index]['isTaken']) return;

    setState(() => _isProcessing = true);
    final docRef =
        FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);
    int firstIdx = data['firstSelectedIndex'];

    if (firstIdx == -1) {
      cards[index]['isFaceUp'] = true;
      await docRef.update({'cards': cards, 'firstSelectedIndex': index});
      _isProcessing = false;
    } else {
      cards[index]['isFaceUp'] = true;
      await docRef.update({'cards': cards});

      if (cards[firstIdx]['rank'] == cards[index]['rank']) {
        await Future.delayed(const Duration(milliseconds: 600));
        cards[firstIdx]['isTaken'] = true;
        cards[index]['isTaken'] = true;
        int newScore = (data['scores'][widget.myPlayerId.toString()] ?? 0) + 1;
        Map<String, dynamic> newScores = Map.from(data['scores']);
        newScores[widget.myPlayerId.toString()] = newScore;
        bool done = cards.every((c) => c['isTaken']);
        await docRef.update({
          'cards': cards,
          'scores': newScores,
          'firstSelectedIndex': -1,
          'winner': done ? (newScores['1'] > newScores['2'] ? 1 : 2) : 0
        });
        _isProcessing = false;
      } else {
        await Future.delayed(const Duration(milliseconds: 1000));
        cards[firstIdx]['isFaceUp'] = false;
        cards[index]['isFaceUp'] = false;
        await docRef.update({
          'cards': cards,
          'firstSelectedIndex': -1,
          'currentTurn': widget.myPlayerId == 1 ? 2 : 1
        });
        _isProcessing = false;
      }
    }
    if (mounted) setState(() {});
  }

  void _showResult(int winner, Map scores) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Game Over"),
        content: Text(
            "Winner: Player $winner\nScore: ${scores['1']} - ${scores['2']}"),
        actions: [
          TextButton(
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              child: const Text("Lobby"))
        ],
      ),
    );
  }
}

// ---------------------------------------------------
// 3. 超小型カードウィジェット
// ---------------------------------------------------
class _CardMini extends StatelessWidget {
  final Map card;
  final bool isMyTurn;
  final Color pColor;

  const _CardMini(
      {required this.card, required this.isMyTurn, required this.pColor});

  @override
  Widget build(BuildContext context) {
    if (card['isTaken']) return const SizedBox.shrink();

    bool isFaceUp = card['isFaceUp'];
    String suit = card['suit'];
    String rank = card['rank'];
    bool isRed = (suit == '♥' || suit == '♦');

    return Container(
      decoration: BoxDecoration(
        color: isFaceUp ? Colors.white : pColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Center(
        child: isFaceUp
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(suit,
                      style: TextStyle(
                          fontSize: 8,
                          color: isRed ? Colors.red : Colors.black)),
                  Text(rank,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isRed ? Colors.red : Colors.black,
                          height: 1)),
                ],
              )
            : const Icon(Icons.help_outline, size: 10, color: Colors.white24),
      ),
    );
  }
}
