import 'package:enmkit/core/education/education_content.dart';
import 'package:enmkit/core/education/quiz_scoring.dart';
import 'package:enmkit/models/education_models.dart';
import 'package:enmkit/repositories/education_repository.dart';
import 'package:flutter/foundation.dart';

/// État du module Éducation énergétique : progression des fiches TP, scores
/// des quiz, fenêtres de scénarios. Tout est persisté localement.
class EducationViewModel extends ChangeNotifier {
  EducationViewModel(this._repo);
  final EducationRepository _repo;

  Map<String, Set<int>> _progress = {};
  Map<String, QuizRecord> _scores = {};
  final Map<String, ScenarioWindow> _scenarios = {};
  bool _loaded = false;

  bool get loaded => _loaded;

  static String _key(String tp, String label) => '$tp/$label';

  Future<void> load() async {
    try {
      _progress = await _repo.loadProgress();
      _scores = await _repo.loadScores();
      _scenarios
        ..clear()
        ..addEntries((await _repo.loadScenarios())
            .map((w) => MapEntry(_key(w.tpCode, w.label), w)));
    } catch (_) {
      // Base indisponible : le module reste consultable (contenu statique).
    }
    _loaded = true;
    notifyListeners();
  }

  // ---- Fiches (checklist) ---------------------------------------------------

  bool isStepDone(String tp, int i) => _progress[tp]?.contains(i) ?? false;

  int doneCount(String tp) => _progress[tp]?.length ?? 0;

  /// Avancement d'une fiche, 0..1.
  double progressOf(EduModule m) =>
      m.steps.isEmpty ? 0 : doneCount(m.code) / m.steps.length;

  Future<void> toggleStep(String tp, int i) async {
    final set = _progress.putIfAbsent(tp, () => <int>{});
    final done = !set.contains(i);
    done ? set.add(i) : set.remove(i);
    notifyListeners();
    try {
      await _repo.setStep(tp, i, done);
    } catch (_) {}
  }

  Future<void> resetSteps(String tp) async {
    _progress.remove(tp);
    notifyListeners();
    try {
      await _repo.resetProgress(tp);
    } catch (_) {}
  }

  // ---- Quiz -----------------------------------------------------------------

  QuizRecord? scoreOf(String tp) => _scores[tp];

  /// Enregistre un résultat ; le meilleur score n'est jamais régressé.
  Future<QuizRecord> recordQuiz(String tp, QuizResult r) async {
    final prev = _scores[tp];
    final rec = QuizRecord(
      tpCode: tp,
      lastScore: r.correct,
      bestScore: QuizScoring.best(prev?.bestScore, r.correct),
      total: r.total,
      at: DateTime.now(),
    );
    _scores[tp] = rec;
    notifyListeners();
    try {
      await _repo.saveScore(rec);
    } catch (_) {}
    return rec;
  }

  /// Nombre de TP dont le quiz est réussi (meilleur score ≥ 70 %).
  int get quizzesPassed => _scores.values
      .where((r) => r.bestPercent >= QuizScoring.passPercent)
      .length;

  // ---- Scénarios A / B ------------------------------------------------------

  ScenarioWindow? scenario(String tp, String label) =>
      _scenarios[_key(tp, label)];

  Future<void> saveScenario(ScenarioWindow w) async {
    _scenarios[_key(w.tpCode, w.label)] = w;
    notifyListeners();
    try {
      await _repo.saveScenario(w);
    } catch (_) {}
  }

  /// Démarre le scénario MAINTENANT, arrondi à l'heure pleine la plus proche
  /// (les trames du kit sont horaires : 09:05 → 09:00, 09:40 → 10:00).
  Future<void> startScenario(String tp, String label, String? kit) =>
      saveScenario(ScenarioWindow(
        tpCode: tp,
        label: label,
        kitNumber: kit,
        startAt: roundHour(DateTime.now()),
      ));

  /// Termine le scénario à l'heure pleine la plus proche (au moins 1 h après
  /// le début).
  Future<void> stopScenario(String tp, String label) async {
    final w = scenario(tp, label);
    if (w == null) return;
    var end = roundHour(DateTime.now());
    if (!end.isAfter(w.startAt)) end = w.startAt.add(const Duration(hours: 1));
    await saveScenario(ScenarioWindow(
      tpCode: tp,
      label: label,
      kitNumber: w.kitNumber,
      startAt: w.startAt,
      endAt: end,
    ));
  }

  Future<void> clearScenario(String tp, String label) async {
    _scenarios.remove(_key(tp, label));
    notifyListeners();
    try {
      await _repo.deleteScenario(tp, label);
    } catch (_) {}
  }

  /// Arrondit à l'heure pleine la plus proche.
  static DateTime roundHour(DateTime d) =>
      DateTime(d.year, d.month, d.day, d.hour + (d.minute >= 30 ? 1 : 0));
}
