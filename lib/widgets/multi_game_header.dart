import 'package:flutter/material.dart';

class MultiGameHeader extends StatelessWidget {
  final int currentTurn;
  final Map<String, dynamic> players;
  final int myId;

  const MultiGameHeader(
      {super.key,
      required this.currentTurn,
      required this.players,
      required this.myId});

  @override
  Widget build(BuildContext context) {
    final activeList = players.values
        .where((p) => p['isActive'] == true)
        .toList()
      ..sort((a, b) => a['id'].compareTo(b['id']));

    return Container(
      height: 70,
      color: Colors.black45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: activeList.length,
        itemBuilder: (context, index) {
          final p = activeList[index];
          final bool isTurn = currentTurn == p['id'];
          return Container(
            width: 100,
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              color: isTurn ? Colors.white12 : Colors.transparent,
              border: isTurn
                  ? Border.all(color: Colors.yellowAccent, width: 2)
                  : null,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(p['name'],
                    style: TextStyle(
                        color:
                            myId == p['id'] ? Colors.blueAccent : Colors.white,
                        fontSize: 10,
                        fontWeight:
                            isTurn ? FontWeight.bold : FontWeight.normal),
                    overflow: TextOverflow.ellipsis),
                Text("${p['score']} pt",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          );
        },
      ),
    );
  }
}
