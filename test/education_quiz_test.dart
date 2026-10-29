// Module Éducation énergétique : intégrité du contenu (7 TP, ≥ 3 questions,
// bilingue) et notation des quiz.

import 'package:enmkit/core/education/education_content.dart';
import 'package:enmkit/core/education/quiz_scoring.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Contenu pédagogique', () {
    test('7 TP, TP1…TP7, dans l\'ordre', () {
      expect(EducationContent.modules.map((m) => m.code),
          ['TP1', 'TP2', 'TP3', 'TP4', 'TP5', 'TP6', 'TP7']);
    });

    test('chaque TP : étapes, acquis, ≥ 3 questions valides, FR et EN', () {
      for (final m in EducationContent.modules) {
        expect(m.steps, isNotEmpty, reason: m.code);
        expect(m.outcomes, isNotEmpty, reason: m.code);
        expect(m.durationMin, greaterThan(0), reason: m.code);
        expect(m.quiz.length, greaterThanOrEqualTo(3), reason: m.code);
        for (final q in m.quiz) {
          expect(q.answerIndex, inInclusiveRange(0, q.choices.length - 1),
              reason: '${m.code} ${q.question.fr}');
          expect(q.question.en, isNotEmpty);
          expect(q.explanation.fr, isNotEmpty);
        }
        expect(m.title.en, isNot(m.title.fr), reason: m.code);
      }
    });

    test('TP comparatifs (TP4, TP5, TP7) : scénarios A/B décrits', () {
      for (final code in ['TP4', 'TP5', 'TP7']) {
        expect(EducationContent.byCode(code)!.scenarioHint, isNotNull,
            reason: code);
      }
      expect(EducationContent.byCode('TP4')!.live, EduLive.compare);
      expect(EducationContent.byCode('TP1')!.live, EduLive.meter);
    });

    test('glossaire et éco-gestes présents', () {
      final terms = EducationContent.glossary.map((g) => g.term.fr).join(' ');
      for (final w in ['kWh', 'Puissance', 'Veille', 'Pointe', 'imp/kWh', 'Disjoncteur']) {
        expect(terms, contains(w));
      }
      expect(EducationContent.tips.length, greaterThanOrEqualTo(8));
    });

    test('repli de langue : « en » → anglais, autre → français', () {
      const b = Bi('Bonjour', 'Hello');
      expect(b.of('en'), 'Hello');
      expect(b.of('fr'), 'Bonjour');
      expect(b.of('de'), 'Bonjour');
    });
  });

  group('Notation des quiz', () {
    final quiz = EducationContent.byCode('TP1')!.quiz; // 4 questions

    test('tout juste => 100 %, réussi', () {
      final r = QuizScoring.score(quiz, quiz.map((q) => q.answerIndex).toList());
      expect(r.correct, quiz.length);
      expect(r.percent, 100);
      expect(r.passed, isTrue);
      expect(r.perQuestion.every((ok) => ok), isTrue);
    });

    test('réponses manquantes ou hors bornes comptent comme fausses', () {
      final r = QuizScoring.score(quiz, [quiz[0].answerIndex, null, 99]);
      expect(r.correct, 1);
      expect(r.total, 4);
      expect(r.percent, 25);
      expect(r.passed, isFalse);
      expect(r.perQuestion, [true, false, false, false]);
    });

    test('seuil de réussite à 70 %', () {
      final three = [
        quiz[0].answerIndex,
        quiz[1].answerIndex,
        quiz[2].answerIndex,
        (quiz[3].answerIndex + 1) % quiz[3].choices.length,
      ];
      final r = QuizScoring.score(quiz, three);
      expect(r.percent, 75);
      expect(r.passed, isTrue);
    });

    test('réponses en trop ignorées ; quiz vide => 0 %', () {
      final r = QuizScoring.score(
          quiz, [...quiz.map((q) => q.answerIndex), 0, 1]);
      expect(r.correct, 4);
      expect(QuizScoring.score(const [], const []).percent, 0);
    });

    test('meilleur score jamais régressé', () {
      expect(QuizScoring.best(null, 2), 2);
      expect(QuizScoring.best(3, 2), 3);
      expect(QuizScoring.best(3, 4), 4);
    });
  });
}
