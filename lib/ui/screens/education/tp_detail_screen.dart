import 'package:enmkit/core/education/education_content.dart';
import 'package:enmkit/providers.dart';
import 'package:enmkit/ui/screens/education/education_screen.dart';
import 'package:enmkit/ui/screens/education/live_cards.dart';
import 'package:enmkit/ui/screens/education/quiz_screen.dart';
import 'package:enmkit/ui/theme/app_theme.dart';
import 'package:enmkit/ui/widgets/common/doodle_background.dart';
import 'package:enmkit/ui/widgets/common/soft_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fiche guidée d'un TP : objectif, notion clé, données en direct du banc,
/// déroulé en liste à cocher (persistée), compétences visées et quiz.
class TpDetailScreen extends ConsumerWidget {
  const TpDetailScreen({super.key, required this.code});
  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final edu = ref.watch(educationProvider);
    final m = EducationContent.byCode(code)!;
    final lang = t.locale;
    final color = tpColor(code);
    final scheme = Theme.of(context).colorScheme;
    final rec = edu.scoreOf(code);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('${m.code} · ${m.title.of(lang)}',
            maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: t.t('edu.reset'),
            icon: const Icon(Icons.restart_alt_rounded),
            onPressed: () => edu.resetSteps(code),
          ),
        ],
      ),
      body: DoodleBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            // Objectif + durée.
            SoftCard(
              shadowTint: color,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconPill(icon: tpIcon(code), color: color, size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(t.t('edu.objective'),
                                style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.5)),
                            const Spacer(),
                            StatusBadge(
                                label: t.tf('edu.minutes', [m.durationMin]),
                                color: color),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(m.objective.of(lang),
                            style: const TextStyle(height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Notion clé.
            SoftCard(
              color: AppTheme.amber.withValues(alpha: 0.12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.tips_and_updates_rounded,
                      color: AppTheme.amber),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.t('edu.keyIdea'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.amber)),
                        const SizedBox(height: 4),
                        Text(m.keyIdea.of(lang),
                            style: const TextStyle(height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (m.live != null) ...[
              const SizedBox(height: 20),
              _Title(t.t('edu.live')),
              EduLiveSection(module: m),
            ],
            const SizedBox(height: 20),
            _Title(
                '${t.t('edu.steps')}  (${edu.doneCount(code)}/${m.steps.length})'),
            SoftCard(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
              child: Column(
                children: [
                  for (var i = 0; i < m.steps.length; i++)
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => edu.toggleStep(code, i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 9),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedContainer(
                              duration: AppTheme.fast,
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: edu.isStepDone(code, i)
                                    ? color
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(color: color, width: 2),
                              ),
                              child: edu.isStepDone(code, i)
                                  ? const Icon(Icons.check_rounded,
                                      size: 16, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${i + 1}. ${m.steps[i].of(lang)}',
                                style: TextStyle(
                                  height: 1.35,
                                  color: edu.isStepDone(code, i)
                                      ? scheme.onSurfaceVariant
                                      : scheme.onSurface,
                                  decoration: edu.isStepDone(code, i)
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _Title(t.t('edu.outcomes')),
            SoftCard(
              child: Column(
                children: [
                  for (final o in m.outcomes)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.verified_rounded, size: 18, color: color),
                          const SizedBox(width: 8),
                          Expanded(child: Text(o.of(lang))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusControl)),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => QuizScreen(code: code)),
              ),
              icon: const Icon(Icons.quiz_rounded),
              label: Text(t.tf('edu.quiz.start', [m.quiz.length])),
            ),
            if (rec != null) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(t.tf('edu.quiz.best', [rec.bestScore, rec.total]),
                    style: TextStyle(color: scheme.onSurfaceVariant)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}
