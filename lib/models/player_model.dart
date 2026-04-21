class PlayerModel {
  final int id;
  final String name;
  final bool isCPU;
  final int cpuLevel;
  final String layoutMode; // 'wide' | 'tall'
  final bool isReady;
  final bool isActive;
  final int score;

  PlayerModel(
      {required this.id,
      required this.name,
      this.isCPU = false,
      this.cpuLevel = 1,
      this.layoutMode = 'wide',
      this.isReady = false,
      this.isActive = false,
      this.score = 0});

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'isCPU': isCPU,
        'cpuLevel': cpuLevel,
        'layoutMode': layoutMode,
        'isReady': isReady,
        'isActive': isActive,
        'score': score
      };

  factory PlayerModel.fromMap(Map<String, dynamic> map) {
    return PlayerModel(
      id: map['id'] ?? 0,
      name: map['name'] ?? 'Player',
      isCPU: map['isCPU'] ?? false,
      cpuLevel: map['cpuLevel'] ?? 1,
      layoutMode: map['layoutMode'] ?? 'wide',
      isReady: map['isReady'] ?? false,
      isActive: map['isActive'] ?? false,
      score: map['score'] ?? 0,
    );
  }
}
