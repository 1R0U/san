class PlayerModel {
  final int id;
  final String name;
  final bool isReady;
  final bool isActive;
  final int score;

  PlayerModel(
      {required this.id,
      required this.name,
      this.isReady = false,
      this.isActive = false,
      this.score = 0});

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'isReady': isReady,
        'isActive': isActive,
        'score': score
      };

  factory PlayerModel.fromMap(Map<String, dynamic> map) {
    return PlayerModel(
      id: map['id'] ?? 0,
      name: map['name'] ?? 'Player',
      isReady: map['isReady'] ?? false,
      isActive: map['isActive'] ?? false,
      score: map['score'] ?? 0,
    );
  }
}
