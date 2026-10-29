import 'package:enmkit/core/education/education_content.dart';

/// Résultat d'un quiz : bonnes réponses, total, pourcentage et détail par
/// question. Logique pure (testable sans base ni UI).
class QuizResult {
  const QuizResult({
    required this.correct,
    required this.total,
    required this.perQuestion,
  });

  final int correct;
  final int total;

  /// `true` si la question i a reçu la bonne réponse (`false` si fausse OU
  /// sans réponse).
  final List<bool> perQuestion;

  /// Pourcentage entier 0–100.
  int get percent => total == 0 ? 0 : ((correct * 100) / total).round();

  /// Réussite : au moins 70 % de bonnes réponses.
  bool get passed => percent >= QuizScoring.passPercent;
}

class QuizScoring {
  QuizScoring._();

  static const int passPercent = 70;

  /// Note les [answers] (index choisi, ou null si pas de réponse) au regard des
  /// [questions]. Les réponses manquantes ou hors bornes comptent comme fausses ;
  /// des réponses en trop sont ignorées.
  static QuizResult score(List<QuizQuestion> questions, List<int?> answers) {
    final per = <bool>[];
    for (var i = 0; i < questions.length; i++) {
      final a = i < answers.length ? answers[i] : null;
      per.add(a != null && a == questions[i].answerIndex);
    }
    return QuizResult(
      correct: per.where((ok) => ok).length,
      total: questions.length,
      perQuestion: per,
    );
  }

  /// Meilleur score conservé : on ne régresse jamais le record.
  static int best(int? previousBest, int newScore) =>
      previousBest == null || newScore > previousBest ? newScore : previousBest;
}
