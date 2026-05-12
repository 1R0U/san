import 'cpu_logic.dart';
import 'game_flow_utils.dart';

class CpuManager {
  static void updateCpuMemoryFromData(
    Map<String, dynamic> data,
    Map<int, Map<int, String>> cpuMemory,
  ) {
    CpuLogic.updateCpuMemoryFromData(data, cpuMemory);
  }

  static List<int> pickCpuMove(
    List<dynamic> cards, {
    required int level,
    required int cpuId,
    required Map<int, Map<int, String>> cpuMemory,
  }) {
    return CpuLogic.pickMove(
      cards,
      level: level,
      cpuId: cpuId,
      cpuMemory: cpuMemory,
    );
  }

  static int resolveWinnerByScore(Map<String, dynamic> players) {
    return GameFlowUtils.resolveWinnerByScore(players);
  }

  static bool hasLegalMove(List<dynamic> cards, int firstSelectedIndex) {
    return GameFlowUtils.hasLegalMove(cards, firstSelectedIndex);
  }

  static List<int> pickAvailableIndices(List<dynamic> cards, int count,
      {int? exclude}) {
    return GameFlowUtils.pickAvailableIndices(cards, count, exclude: exclude);
  }

  static void applyPermanentReveal(
      List<dynamic> cards, int viewerId, List<int> indices) {
    GameFlowUtils.applyPermanentReveal(cards, viewerId, indices);
  }
}
