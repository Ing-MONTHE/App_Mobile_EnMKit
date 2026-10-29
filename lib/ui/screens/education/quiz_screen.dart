import 'package:enmkit/core/education/education_content.dart';
import 'package:enmkit/core/education/quiz_scoring.dart';
import 'package:enmkit/providers.dart';
import 'package:enmkit/ui/screens/education/education_screen.dart';
import 'package:enmkit/ui/theme/app_theme.dart';
import 'package:enmkit/ui/widgets/common/doodle_background.dart';
import 'package:enmkit/ui/widgets/common/soft_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Quiz d'un TP : choix unique par question, correction détaillée avec
/// explications, score enregistré localement (meilleur score conservé).
class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key, required this.code});
  final String code;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  late final EduModule _m = EducationContent.byCode(widget.code)!;
  late List<int?> _answers = List<int?>.filled(_m.quiz.length, null);
  QuizResult? _result;

  Future<void> _validate() async {
    final t = ref.read(tProvider);
    if (_answers.any((a) => a == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.t('edu.quiz.answerAll'))));
      return;
    }
    final r = QuizScoring.score(_m.quiz, _answers);
    await ref.read(educationProvider).recordQuiz(widget.code, r);
    if (!mounted) return;
    setState(() => _result = r);
  }

  void _retry() => setState(() {
        _answers = List<int?>.filled(_m.quiz.length, null);
        _result = null;
      });

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);
    final lang = t.locale;
    final color = tpColor(widget.code);
    final scheme = Theme.of(context).colorScheme;
    final r = _result;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text('${t.t('edu.quiz')} · ${_m.code}')),
      body: DoodleBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            if (r != null) ...[
              SoftCard(
                color: (r.passed ? AppTheme.emerald : AppTheme.amber)
                    .withValues(alpha: 0.14),
                child: Row(
                  children: [
                    Icon(
                        r.passed
                            ? Icons.emoji_events_rounded
                            : Icons.replay_rounded,
                        color: r.passed ? AppTheme.emerald : AppTheme.amber,
                        size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              t.tf('edu.quiz.result',
                                  [r.correct, r.total, r.percent]),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16)),
                          Text(t.t(r.passed
                              ? 'edu.quiz.passed'
                              : 'edu.quiz.failed')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            for (var qi = 0; qi < _m.quiz.length; qi++) ...[
              _QuestionCard(
                index: qi,
                question: _m.quiz[qi],
                lang: lang,
                color: color,
                selected: _answers[qi],
                corrected: r != null,
                onSelect: r != null
                    ? null
                    : (c) => setState(() => _answers[qi] = c),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 6),
            if (r == null)
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: _validate,
                icon: const Icon(Icons.check_circle_rounded),
                label: Text(t.t('edu.quiz.validate')),
              )
            else
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    foregroundColor: scheme.primary),
                onPressed: _retry,
                icon: const Icon(Icons.replay_rounded),
                label: Text(t.t('edu.quiz.retry')),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.question,
    required this.lang,
    required this.color,
    required this.selected,
    required this.corrected,
    required this.onSelect,
  });
  final int index;
  final QuizQuestion question;
  final String lang;
  final Color color;
  final int? selected;
  final bool corrected;
  final ValueChanged<int>? onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${index + 1}. ${question.question.of(lang)}',
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 10),
          for (var c = 0; c < question.choices.length; c++)
            Builder(builder: (context) {
              final isSel = selected == c;
              final isRight = c == question.answerIndex;
              Color border = scheme.outline.withValues(alpha: 0.25);
              Color? fill;
              IconData icon = isSel
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded;
              Color iconColor = isSel ? color : scheme.onSurfaceVariant;
              if (corrected && isRight) {
                border = AppTheme.emerald;
                fill = AppTheme.emerald.withValues(alpha: 0.12);
                icon = Icons.check_circle_rounded;
                iconColor = AppTheme.emerald;
              } else if (corrected && isSel) {
                border = AppTheme.coral;
                fill = AppTheme.coral.withValues(alpha: 0.10);
                icon = Icons.cancel_rounded;
                iconColor = AppTheme.coral;
              } else if (isSel) {
                border = color;
                fill = color.withValues(alpha: 0.08);
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: fill ?? Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: border, width: 1.4),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onSelect == null ? null : () => onSelect!(c),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 11),
                      child: Row(
                        children: [
                          Icon(icon, size: 20, color: iconColor),
                          const SizedBox(width: 10),
                          Expanded(child: Text(question.choices[c].of(lang))),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          if (corrected) ...[
            const SizedBox(height: 4),
            Text(question.explanation.of(lang),
                style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                    height: 1.35)),
          ],
        ],
      ),
    );
  }
}
