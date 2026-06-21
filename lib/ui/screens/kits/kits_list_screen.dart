import 'package:enmkit/core/constants/defaults.dart';
import 'package:enmkit/models/kit_model.dart';
import 'package:enmkit/providers.dart';
import 'package:enmkit/ui/screens/kit_detail/kit_detail_screen.dart';
import 'package:enmkit/ui/screens/kits/scan_kit_screen.dart';
import 'package:enmkit/ui/theme/app_theme.dart';
import 'package:enmkit/ui/widgets/common/app_sheet.dart';
import 'package:enmkit/ui/widgets/common/brand_loader.dart';
import 'package:enmkit/ui/widgets/common/premium.dart';
import 'package:enmkit/ui/widgets/common/state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Accueil multi-kits, style fintech : héros dégradé, stats animées et liste de
/// cartes premium avec animation d'entrée échelonnée.
class KitsListScreen extends ConsumerWidget {
  const KitsListScreen({super.key});

  static const _accents = [
    AppTheme.indigo,
    AppTheme.emerald,
    AppTheme.violet,
    AppTheme.coral,
    AppTheme.cyan,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kitVM = ref.watch(kitProvider);
    final kits = kitVM.kits;
    final t = ref.watch(tProvider);

    return Stack(
      children: [
        if (kitVM.isLoading)
          BrandLoader(message: t.t('kits.loading'))
        else
          RefreshIndicator(
            onRefresh: () => ref.read(kitProvider).fetchKits(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _Header(
                    kits: kits,
                    onScan: () => _importKit(context, ref),
                  ),
                ),
                if (kits.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateView(
                      icon: Icons.devices_other_rounded,
                      title: t.t('kits.empty.title'),
                      message: t.t('kits.empty.msg'),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 130),
                    sliver: SliverList.separated(
                      itemCount: kits.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, i) {
                        final kit = kits[i];
                        // Glisser une carte (gauche OU droite) propose la
                        // suppression, avec confirmation explicite avant l'action.
                        return Dismissible(
                          key: ValueKey('kit_${kit.kitNumber ?? i}'),
                          direction: DismissDirection.horizontal,
                          background: const _DeleteBackground(alignStart: true),
                          secondaryBackground:
                              const _DeleteBackground(alignStart: false),
                          confirmDismiss: (_) =>
                              _confirmDeleteKit(context, ref, kit),
                          onDismissed: (_) => _deleteKit(context, ref, kit),
                          child: _KitCard(
                            kit: kit,
                            accent: _accents[i % _accents.length],
                            onTap: () => _openKit(context, ref, kit),
                          ),
                        )
                            .animate()
                            .fadeIn(
                                delay: (80 * i).ms,
                                duration: 380.ms,
                                curve: Curves.easeOut)
                            .slideY(
                                begin: 0.18,
                                end: 0,
                                curve: Curves.easeOutCubic);
                      },
                    ),
                  ),
              ],
            ),
          ),
        Positioned(
          right: 20,
          bottom: 100,
          child: _AddFab(onTap: () => _showAddKitDialog(context, ref)),
        ),
      ],
    );
  }

  void _openKit(BuildContext context, WidgetRef ref, KitModel kit) {
    ref.read(selectedKitProvider.notifier).state = kit;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => KitDetailScreen(kit: kit)),
    );
  }

  /// Demande une confirmation explicite avant de supprimer un kit (le glissement
  /// ne fait QUE proposer l'action ; rien n'est supprimé sans ce « oui »).
  Future<bool> _confirmDeleteKit(
      BuildContext context, WidgetRef ref, KitModel kit) async {
    final t = ref.read(tProvider);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded,
            color: AppTheme.danger, size: 30),
        title: Text(t.t('kits.delete.title')),
        content: Text(
          t.tf('kits.delete.msg', [kit.displayName]),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.t('common.cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.t('common.delete')),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  /// Supprime le kit (et ses données), nettoie la sélection si besoin,
  /// resynchronise les numéros surveillés côté natif, puis confirme à l'écran.
  Future<void> _deleteKit(
      BuildContext context, WidgetRef ref, KitModel kit) async {
    final t = ref.read(tProvider);
    final name = kit.displayName;

    if (ref.read(selectedKitProvider)?.kitNumber == kit.kitNumber) {
      ref.read(selectedKitProvider.notifier).state = null;
    }

    await ref.read(kitProvider).deleteKit(kit);

    // Met à jour la liste des kits surveillés par le récepteur natif.
    try {
      final remaining = ref
          .read(kitProvider)
          .kits
          .map((k) => k.kitNumber)
          .whereType<String>()
          .where((n) => n.isNotEmpty)
          .toList();
      await ref.read(backgroundSmsBridgeProvider).setKitNumbers(remaining);
    } catch (_) {
      // Canal natif indisponible : ignore (resync au prochain démarrage).
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.tf('kits.deleted', [name]))),
      );
    }
  }

  Future<void> _importKit(BuildContext context, WidgetRef ref) async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScanKitScreen()),
    );
    if (code == null || code.isEmpty) return;
    final t = ref.read(tProvider);
    try {
      final kit = await ref.read(dbRegeneratorProvider).regenerateFromJson(code);
      await ref.read(kitProvider).fetchKits();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.tf('kits.imported', [kit.displayName]))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.tf('kits.importFailed', [e]))),
        );
      }
    }
  }

  Future<void> _showAddKitDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final numberController = TextEditingController();
    final t = ref.read(tProvider);

    // Nombre de lignes à créer : 4, 7 ou personnalisé (1..max).
    int lineCount = DefaultData.defaultLineCount;
    bool custom = false;

    await showAppSheet<void>(
      context: context,
      icon: Icons.add_home_work_rounded,
      title: t.t('kits.new'),
      subtitle: t.t('kits.new.sub'),
      accent: AppTheme.indigo,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Column(
          children: [
            SheetField(
              controller: nameController,
              label: t.t('kits.name'),
              hint: t.t('kits.name.hint'),
              icon: Icons.label_outline_rounded,
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            SheetField(
              controller: numberController,
              label: t.t('kits.gsm'),
              hint: 'Ex : 6XX XX XX XX',
              icon: Icons.sim_card_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  t.t('kits.lineCount'),
                  style: TextStyle(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Row(
              children: [
                _LineCountChip(
                  label: '4',
                  selected: !custom && lineCount == 4,
                  onTap: () => setLocal(() {
                    custom = false;
                    lineCount = 4;
                  }),
                ),
                const SizedBox(width: 10),
                _LineCountChip(
                  label: '7',
                  selected: !custom && lineCount == 7,
                  onTap: () => setLocal(() {
                    custom = false;
                    lineCount = 7;
                  }),
                ),
                const SizedBox(width: 10),
                _LineCountChip(
                  label: t.t('kits.lineCount.custom'),
                  selected: custom,
                  onTap: () => setLocal(() {
                    custom = true;
                    if (lineCount == 4 || lineCount == 7) lineCount = 5;
                  }),
                ),
              ],
            ),
            if (custom) ...[
              const SizedBox(height: 14),
              _LineCountStepper(
                value: lineCount,
                min: 1,
                max: DefaultData.maxRelaysPerKit,
                onChanged: (v) => setLocal(() => lineCount = v),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  final number = numberController.text.trim();
                  final name = nameController.text.trim();
                  if (number.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(t.t('kits.gsm.required'))),
                    );
                    return;
                  }
                  await ref.read(kitProvider).addKit(
                        KitModel(
                            kitNumber: number,
                            name: name.isEmpty ? null : name),
                      );
                  // Crée le nombre de lignes choisi pour le nouveau kit.
                  await ref
                      .read(relayRepositoryProvider)
                      .seedLines(number, lineCount);
                  ref.invalidate(kitRelaysProvider(number));
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                icon: const Icon(Icons.check_rounded),
                label: Text(t.t('kits.add.cta')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pastille de choix du nombre de lignes (4 / 7 / Personnalisé).
class _LineCountChip extends StatelessWidget {
  const _LineCountChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary
                : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

/// Sélecteur de quantité (− valeur +) pour le mode personnalisé.
class _LineCountStepper extends StatelessWidget {
  const _LineCountStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget btn(IconData icon, bool enabled, VoidCallback onTap) {
      return GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: enabled
                ? scheme.primary.withValues(alpha: 0.12)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          ),
          child: Icon(icon,
              size: 20,
              color: enabled ? scheme.primary : scheme.outline),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          btn(Icons.remove_rounded, value > min,
              () => onChanged(value - 1)),
          Text(
            '$value',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          btn(Icons.add_rounded, value < max, () => onChanged(value + 1)),
        ],
      ),
    );
  }
}

/// En-tête : salutation + héros dégradé avec stats animées.
class _Header extends ConsumerWidget {
  const _Header({required this.kits, required this.onScan});
  final List<KitModel> kits;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final t = ref.watch(tProvider);
    final configured = kits.where((k) => k.isConfigured).length;
    final pending = kits.length - configured;
    final configuredLabel = configured > 1
        ? t.tf('kits.configuredPlural', [configured])
        : t.tf('kits.configured', [configured]);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.t('kits.hello'),
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(t.t('kits.title'),
                        style: Theme.of(context).textTheme.headlineMedium),
                  ],
                ),
              ),
              GlassIconButton(
                  icon: Icons.qr_code_scanner_rounded, onTap: onScan),
            ],
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0),
          const SizedBox(height: 18),
          GradientHeroCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.dashboard_rounded,
                          color: Colors.white, size: 21),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      t.t('kits.park'),
                      style: GoogleFonts.chakraPetch(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AnimatedCount(
                      value: kits.length,
                      style: GoogleFonts.chakraPetch(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        kits.length > 1
                            ? t.t('kits.countPlural')
                            : t.t('kits.count'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _HeroChip(
                        icon: Icons.check_circle_rounded,
                        label: configuredLabel),
                    const SizedBox(width: 10),
                    _HeroChip(
                        icon: Icons.schedule_rounded,
                        label: t.tf('kits.pending', [pending])),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 450.ms).slideY(
              begin: 0.1, end: 0, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte d'un kit, premium avec accent coloré et profondeur.
class _KitCard extends ConsumerWidget {
  const _KitCard({
    required this.kit,
    required this.accent,
    required this.onTap,
  });
  final KitModel kit;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = ref.watch(tProvider);
    final configured = kit.isConfigured;
    final statusColor = configured ? AppTheme.emerald : AppTheme.amber;

    // Surface translucide : le motif de fond transparaît (immersion).
    final cardColor = (isDark ? const Color(0xFF1E2038) : Colors.white)
        .withValues(alpha: isDark ? 0.55 : 0.62);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.07 : 0.55),
        ),
        boxShadow: AppTheme.elevedShadow(tint: accent, strength: 0.22),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [accent, Color.lerp(accent, Colors.white, 0.3)!],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.electrical_services_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                // Nom + numéro côte à côte (compact, une ligne).
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          kit.displayName,
                          style: const TextStyle(
                              fontSize: 15.5, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                            color:
                                scheme.onSurfaceVariant.withValues(alpha: 0.5),
                            shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        kit.kitNumber ?? t.t('kits.noNumber'),
                        style: TextStyle(
                            color: scheme.onSurfaceVariant, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Pastille de statut compacte (point coloré).
                Container(
                  width: 9,
                  height: 9,
                  decoration:
                      BoxDecoration(color: statusColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Icon(Icons.chevron_right_rounded,
                    size: 20, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fond rouge révélé lorsqu'on glisse une carte kit (indication « supprimer »).
/// Affiché des deux côtés pour que le glissement gauche OU droite fonctionne.
class _DeleteBackground extends ConsumerWidget {
  const _DeleteBackground({required this.alignStart});
  final bool alignStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.danger,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: alignStart ? Alignment.centerLeft : Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 24),
          const SizedBox(width: 8),
          Text(
            t.t('common.delete'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bouton flottant compact « + » à dégradé de marque.
class _AddFab extends StatelessWidget {
  const _AddFab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: AppTheme.brandGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppTheme.elevedShadow(tint: AppTheme.indigo, strength: 1),
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}
