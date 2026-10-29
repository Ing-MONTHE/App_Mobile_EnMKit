/// Score enregistré d'un quiz de TP (table `edu_quiz_scores`).
class QuizRecord {
  const QuizRecord({
    required this.tpCode,
    required this.lastScore,
    required this.bestScore,
    required this.total,
    required this.at,
  });
  final String tpCode;
  final int lastScore;
  final int bestScore;
  final int total;
  final DateTime at;

  int get bestPercent => total == 0 ? 0 : (bestScore * 100 / total).round();

  Map<String, dynamic> toMap() => {
        'tpCode': tpCode,
        'lastScore': lastScore,
        'bestScore': bestScore,
        'total': total,
        'at': at.toIso8601String(),
      };

  factory QuizRecord.fromMap(Map<String, dynamic> m) => QuizRecord(
        tpCode: m['tpCode'] as String,
        lastScore: (m['lastScore'] as num).toInt(),
        bestScore: (m['bestScore'] as num).toInt(),
        total: (m['total'] as num).toInt(),
        at: DateTime.tryParse(m['at'] as String? ?? '') ?? DateTime(2000),
      );
}

/// Fenêtre horaire d'un scénario de TP comparatif (« A » ou « B »), table
/// `edu_scenarios`. [endAt] null = scénario démarré mais pas encore terminé.
class ScenarioWindow {
  const ScenarioWindow({
    required this.tpCode,
    required this.label,
    required this.startAt,
    this.endAt,
    this.kitNumber,
  });
  final String tpCode;
  final String label;
  final DateTime startAt;
  final DateTime? endAt;
  final String? kitNumber;

  bool get isRunning => endAt == null;

  Map<String, dynamic> toMap() => {
        'tpCode': tpCode,
        'label': label,
        'kitNumber': kitNumber,
        'startAt': startAt.toIso8601String(),
        'endAt': endAt?.toIso8601String(),
      };

  factory ScenarioWindow.fromMap(Map<String, dynamic> m) => ScenarioWindow(
        tpCode: m['tpCode'] as String,
        label: m['label'] as String,
        kitNumber: m['kitNumber'] as String?,
        startAt: DateTime.parse(m['startAt'] as String),
        endAt: DateTime.tryParse(m['endAt'] as String? ?? ''),
      );
}
