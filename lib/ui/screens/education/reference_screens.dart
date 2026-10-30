import 'package:enmkit/core/education/education_content.dart';
import 'package:enmkit/providers.dart';
import 'package:enmkit/ui/screens/education/education_screen.dart';
import 'package:enmkit/ui/theme/app_theme.dart';
import 'package:enmkit/ui/widgets/common/doodle_background.dart';
import 'package:enmkit/ui/widgets/common/soft_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Glossaire de l'énergie (kWh, puissance, veille, pointe, imp/kWh…).
class GlossaryScreen extends ConsumerWidget {
  const GlossaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final scheme = Theme.of(context).colorScheme;
    final entries = [...EducationContent.glossary]
      ..sort((a, b) => a.term.of(t.locale).compareTo(b.term.of(t.locale)));
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(t.t('edu.glossary'))),
      body: DoodleBackground(
        underAppBar: true,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final g = entries[i];
            return SoftCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(g.term.of(t.locale),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppTheme.violet)),
                  const SizedBox(height: 4),
                  Text(g.definition.of(t.locale),
                      style: TextStyle(
                          color: scheme.onSurfaceVariant, height: 1.35)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Liste complète des éco-gestes, par catégorie.
class TipsScreen extends ConsumerWidget {
  const TipsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(t.t('edu.tips'))),
      body: DoodleBackground(
        underAppBar: true,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            for (final cat in TipCategory.values) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                child: Row(
                  children: [
                    Icon(tipIcon(cat), size: 18, color: AppTheme.emerald),
                    const SizedBox(width: 6),
                    Text(t.t('edu.tip.cat.${cat.name}'),
                        style: Theme.of(context).textTheme.titleSmall),
                  ],
                ),
              ),
              for (final tip
                  in EducationContent.tips.where((x) => x.category == cat))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SoftCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tip.title.of(t.locale),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14.5)),
                        const SizedBox(height: 4),
                        Text(tip.body.of(t.locale),
                            style: TextStyle(
                                color: scheme.onSurfaceVariant, height: 1.35)),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
