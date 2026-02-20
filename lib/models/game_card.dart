class GameCard {
  final String rank;
  final String suit;
  bool isFaceUp;
  bool isTaken;
  List<int> permViewers;

  GameCard({
    required this.rank,
    required this.suit,
    this.isFaceUp = false,
    this.isTaken = false,
    this.permViewers = const [],
  });

  Map<String, dynamic> toMap() => {
        'rank': rank,
        'suit': suit,
        'isFaceUp': isFaceUp,
        'isTaken': isTaken,
        'permViewers': permViewers,
      };

  static GameCard fromMap(Map<String, dynamic> map) {
    return GameCard(
      rank: map['rank'] ?? '',
      suit: map['suit'] ?? '',
      isFaceUp: map['isFaceUp'] ?? false,
      isTaken: map['isTaken'] ?? false,
      permViewers: (map['permViewers'] as List? ?? []).cast<int>(),
    );
  }
}
