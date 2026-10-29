import 'package:enmkit/core/education/education_content.dart';
import 'package:enmkit/models/kit_model.dart';
import 'package:enmkit/providers.dart';
import 'package:enmkit/ui/screens/assistant/assistant_screen.dart';
import 'package:enmkit/ui/screens/education/reference_screens.dart';
import 'package:enmkit/ui/screens/education/tp_detail_screen.dart';
import 'package:enmkit/ui/theme/app_theme.dart';
import 'package:enmkit/ui/widgets/common/premium.dart';
import 'package:enmkit/ui/widgets/common/soft_card.dart';
import 'package:enmkit/viewmodels/assistant_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Couleur associée à chaque TP (pastilles, barres de progression).
Color tpColor(String code) => switch (code) {
      'TP1' => AppTheme.indigo,
      'TP2' => AppTheme.violet,
      'TP3' => AppTheme.cyan,
      'TP4' => AppTheme.emerald,
      'TP5' => AppTheme.amber,
      'TP6' => AppTheme.pink,
      _ => AppTheme.coral,
    };

IconData tpIcon(String code) => switch (code) {
      'TP1' => Icons.speed_rounded,
      'TP2' => Icons.cable_rounded,
      'TP3' => Icons.sms_rounded,
      'TP4' => Icons.compare_arrows_rounded,
      'TP5' => Icons.eco_rounded,
      'TP6' => Icons.hub_rounded,
      _ => Icons.groups_rounded,
    };

/// Kit servant aux données « en direct » des fiches : celui choisi par
/// l'utilisateur, sinon le premier kit. null si aucun kit.
KitModel? educationKit(WidgetRef ref) {
  final kits = ref.watch(kitProvider).kits;
  if (kits.isEmpty) return null;
  final chosen = ref.watch(educationKitProvider);
  for (final k in kits) {
    if (k.kitNumber == chosen) return k;
  }
  return kits.first;
}

/// Module « Éducation énergétique » (onglet Apprendre de la coquille) :
/// les 7 TP du Smart Home Learning Lab, éco-gestes, glossaire, assistant.
class EducationScreen extends ConsumerWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final edu = ref.watch(educationProvider);
    final lang = t.locale;
    final scheme = Theme.of(context).colorScheme;
    final steps = EducationContent.modules
        .fold<int>(0, (s, m) => s + edu.doneCount(m.code));
    final totalSteps =
        EducationContent.modules.fold<int>(0, (s, m) => s + m.steps.length);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        Text(t.t('edu.title'),
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(t.t('edu.subtitle'),
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14)),
        const SizedBox(height: 18),
        GradientHeroCard(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.school_rounded,
                    color: Colors.white, size: 27),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${edu.quizzesPassed}/7',
                      style: GoogleFonts.chakraPetch(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          height: 1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.tf('edu.stats', [edu.quizzesPassed, '$steps/$totalSteps']),
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const EducationKitSelector(),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(t.t('edu.labs'),
              style: Theme.of(context).textTheme.titleMedium),
        ),
        ...[
          for (final m in EducationContent.modules)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TpCard(module: m, lang: lang),
            ),
        ].animate(interval: 50.ms).fadeIn(duration: 300.ms).slideX(
            begin: 0.05, end: 0, duration: 300.ms),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(t.t('edu.tips'),
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              TextButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const TipsScreen())),
                child: const Icon(Icons.arrow_forward_rounded),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: EducationContent.tips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final tip = EducationContent.tips[i];
              return SizedBox(
                width: 240,
                child: SoftCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconPill(
                              icon: tipIcon(tip.category),
                              color: AppTheme.emerald,
                              size: 30),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(tip.title.of(lang),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(tip.body.of(lang),
                            overflow: TextOverflow.fade,
                            style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontSize: 12.3,
                                height: 1.3)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        SoftCard(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const GlossaryScreen())),
          child: Row(
            children: [
              const IconPill(
                  icon: Icons.menu_book_rounded,
                  color: AppTheme.violet,
                  size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Text(t.t('edu.glossary'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              Text('${EducationContent.glossary.length}',
                  style: TextStyle(color: scheme.onSurfaceVariant)),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SoftCard(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AssistantScreen(
                kitNumber: educationKit(ref)?.kitNumber,
                initialAudience: AssistantAudience.learner,
              ),
            ),
          ),
          child: Row(
            children: [
              const IconPill(
                  icon: Icons.forum_rounded, color: AppTheme.indigo, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.t('edu.assistant'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(t.t('edu.assistant.sub'),
                        style: TextStyle(
                            color: scheme.onSurfaceVariant, fontSize: 12.5)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ],
    );
  }
}

IconData tipIcon(TipCategory c) => switch (c) {
      TipCategory.standby => Icons.power_settings_new_rounded,
      TipCategory.lighting => Icons.lightbulb_rounded,
      TipCategory.peak => Icons.wb_twilight_rounded,
      TipCategory.cooling => Icons.ac_unit_rounded,
      TipCategory.habits => Icons.self_improvement_rounded,
      TipCategory.cost => Icons.payments_rounded,
    };

/// Sélecteur du kit « banc » dont les mesures alimentent les fiches.
class EducationKitSelector extends ConsumerWidget {
  const EducationKitSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final kits = ref.watch(kitProvider).kits;
    final scheme = Theme.of(context).colorScheme;
    if (kits.isEmpty) {
      return SoftCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const IconPill(
                icon: Icons.info_outline_rounded,
                color: AppTheme.amber,
                size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Text(t.t('edu.live.noKit'),
                  style:
                      TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5)),
            ),
          ],
        ),
      );
    }
    final current = educationKit(ref);
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          const IconPill(
              icon: Icons.electrical_services_rounded,
              color: AppTheme.indigo,
              size: 34),
          const SizedBox(width: 10),
          Text(t.t('edu.live.kit'),
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: current?.kitNumber,
                items: [
                  for (final k in kits)
                    if (k.kitNumber != null)
                      DropdownMenuItem(
                        value: k.kitNumber,
                        child: Text(k.displayName,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                ],
                onChanged: (v) =>
                    ref.read(educationKitProvider.notifier).state = v,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TpCard extends ConsumerWidget {
  const _TpCard({required this.module, required this.lang});
  final EduModule module;
  final String lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final edu = ref.watch(educationProvider);
    final scheme = Theme.of(context).colorScheme;
    final color = tpColor(module.code);
    final rec = edu.scoreOf(module.code);
    final progress = edu.progressOf(module);
    return SoftCard(
      shadowTint: color,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TpDetailScreen(code: module.code)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconPill(icon: tpIcon(module.code), color: color, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${module.code} · ${t.tf('edu.minutes', [module.durationMin])}',
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 12),
                    ),
                    Text(module.title.of(lang),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  ],
                ),
              ),
              if (rec != null)
                StatusBadge(
                  label: '${rec.bestScore}/${rec.total}',
                  color: rec.bestPercent >= 70
                      ? AppTheme.emerald
                      : AppTheme.amber,
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: color,
              backgroundColor: scheme.onSurfaceVariant.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}
