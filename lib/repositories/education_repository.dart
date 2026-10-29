import 'package:enmkit/core/db_service.dart';
import 'package:enmkit/models/education_models.dart';
import 'package:sqflite/sqflite.dart';

/// Persistance locale du module Éducation : cases cochées des fiches, scores
/// des quiz et fenêtres « Scénario A / B ». 100 % hors-ligne.
class EducationRepository {
  final DBService _dbService;
  EducationRepository(this._dbService);

  /// Étapes cochées, par code de TP.
  Future<Map<String, Set<int>>> loadProgress() async {
    final db = await _dbService.database;
    final rows = await db.query('edu_progress', where: 'done = 1');
    final out = <String, Set<int>>{};
    for (final r in rows) {
      out.putIfAbsent(r['tpCode'] as String, () => <int>{})
          .add((r['stepIndex'] as num).toInt());
    }
    return out;
  }

  Future<void> setStep(String tpCode, int stepIndex, bool done) async {
    final db = await _dbService.database;
    await db.insert(
      'edu_progress',
      {'tpCode': tpCode, 'stepIndex': stepIndex, 'done': done ? 1 : 0},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> resetProgress(String tpCode) async {
    final db = await _dbService.database;
    await db.delete('edu_progress', where: 'tpCode = ?', whereArgs: [tpCode]);
  }

  Future<Map<String, QuizRecord>> loadScores() async {
    final db = await _dbService.database;
    final rows = await db.query('edu_quiz_scores');
    return {
      for (final r in rows) r['tpCode'] as String: QuizRecord.fromMap(r),
    };
  }

  Future<void> saveScore(QuizRecord record) async {
    final db = await _dbService.database;
    await db.insert('edu_quiz_scores', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ScenarioWindow>> loadScenarios() async {
    final db = await _dbService.database;
    final rows = await db.query('edu_scenarios');
    return rows.map(ScenarioWindow.fromMap).toList();
  }

  Future<void> saveScenario(ScenarioWindow w) async {
    final db = await _dbService.database;
    await db.insert('edu_scenarios', w.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteScenario(String tpCode, String label) async {
    final db = await _dbService.database;
    await db.delete('edu_scenarios',
        where: 'tpCode = ? AND label = ?', whereArgs: [tpCode, label]);
  }
}
