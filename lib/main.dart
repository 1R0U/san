import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: CardSortGame(),
  ));
}

class CardSortGame extends StatefulWidget {
  const CardSortGame({super.key});
  @override
  State<CardSortGame> createState() => _CardSortGameState();
}

class _CardSortGameState extends State<CardSortGame> {
  List<Map<String, String>> poolCards = [];
  Map<String, List<String>> collections = {};
  List<String> genres = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadGame();
  }

  Future<void> loadGame() async {
    try {
      final String response = await rootBundle.loadString('assets/cards.json');
      final data = json.decode(response);
      List<Map<String, String>> tempPool = [];
      List<String> tempGenres = [];

      for (var cat in data['categories']) {
        String g = cat['genre'];
        tempGenres.add(g);
        collections[g] = [];
        for (var item in cat['items']) {
          tempPool.add({'text': item, 'genre': g});
        }
      }
      setState(() {
        genres = tempGenres;
        poolCards = tempPool..shuffle();
        isLoading = false;
      });
    } catch (e) {
      debugPrint("エラー: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('散'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: () => loadGame()),
        ],
      ),
      body: Column(
        children: [
          // 上部：バラバラのカード
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              color: Colors.grey[100],
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: poolCards
                      .map((c) => Draggable<Map<String, String>>(
                            data: c,
                            feedback:
                                CardView(text: c['text']!, isDragging: true),
                            childWhenDragging: Opacity(
                                opacity: 0.2,
                                child: CardView(text: c['text']!)),
                            child: CardView(text: c['text']!),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
          const Divider(height: 1, thickness: 2),
          // 下部：ジャンル別ボックス
          Expanded(
            flex: 3,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              itemCount: genres.length,
              itemBuilder: (context, index) {
                final g = genres[index];
                return DragTarget<Map<String, String>>(
                  onWillAccept: (data) => data?['genre'] == g,
                  onAccept: (data) {
                    setState(() {
                      collections[g]!.add(data!['text']!);
                      poolCards.remove(data);
                    });
                    if (poolCards.isEmpty) showWinDialog();
                  },
                  builder: (context, candidate, _) => Container(
                    width: 160,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: candidate.isNotEmpty
                          ? Colors.orange[50]
                          : Colors.white,
                      border: Border.all(color: Colors.orange, width: 2),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5)
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(12)),
                          ),
                          child: Text(g,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(8),
                            children: collections[g]!
                                .map((t) => Card(
                                      margin: const EdgeInsets.only(bottom: 4),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(t,
                                            textAlign: TextAlign.center),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('🎉 クリア！'),
        content: const Text('すべてのカードを正しく仕分けました！'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              loadGame();
            },
            child: const Text('もう一度遊ぶ'),
          ),
        ],
      ),
    );
  }
}

class CardView extends StatelessWidget {
  final String text;
  final bool isDragging;
  const CardView({super.key, required this.text, this.isDragging = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.orange.shade200),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDragging ? 0.3 : 0.1),
              blurRadius: isDragging ? 10 : 4,
              offset: const Offset(2, 2),
            )
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
